//
//  HealthTool.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/17/25.
//

import Foundation
import FoundationModels
import HealthKit

/// `HealthTool` provides access to health data using HealthKit.
///
/// This tool can query various health metrics like steps, heart rate, and workouts.
/// It requires appropriate permissions to access health data.
struct HealthTool: Tool {
  
  /// The name of the tool, used for identification.
  let name = "queryHealth"
  /// A brief description of the tool's functionality.
  let description = "Query health data including steps, heart rate, workouts, and other health metrics"
  
  /// Arguments for health operations.
  @Generable
  struct Arguments {
    /// The type of health data to query: "steps", "heartRate", "workouts", "sleep", "calories", "distance"
    @Guide(description: "The type of health data to query: 'steps', 'heartRate', 'workouts', 'sleep', 'calories', 'distance'")
    var dataType: String
    
    /// Time range: "today", "yesterday", "thisWeek", "lastWeek", "thisMonth", or custom dates
    @Guide(description: "Time range: 'today', 'yesterday', 'thisWeek', 'lastWeek', 'thisMonth', or custom dates")
    var timeRange: String?
    
    /// Start date in ISO 8601 format (for custom date range)
    @Guide(description: "Start date in ISO 8601 format (for custom date range)")
    var startDate: String?
    
    /// End date in ISO 8601 format (for custom date range)
    @Guide(description: "End date in ISO 8601 format (for custom date range)")
    var endDate: String?
  }
  
  /// Health data structure
  struct HealthData: Encodable {
    let dataType: String
    let value: Double
    let unit: String
    let startDate: String
    let endDate: String
    let samples: [HealthSample]?
  }
  
  struct HealthSample: Encodable {
    let value: Double
    let date: String
    let source: String?
  }
  
  struct WorkoutData: Encodable {
    let activityType: String
    let duration: Double
    let energyBurned: Double?
    let distance: Double?
    let startDate: String
    let endDate: String
  }
  
  private let healthStore = HKHealthStore()
  private let dateFormatter = ISO8601DateFormatter()
  
  func call(arguments: Arguments) async throws -> ToolOutput {
    // Check if HealthKit is available
    guard HKHealthStore.isHealthDataAvailable() else {
      return createErrorOutput(error: HealthError.healthDataNotAvailable)
    }
    
    // Request authorization
    let authorized = try await requestHealthAuthorization(for: arguments.dataType)
    guard authorized else {
      return createErrorOutput(error: HealthError.authorizationDenied)
    }
    
    // Get date range
    let (startDate, endDate) = getDateRange(from: arguments.timeRange, 
                                           startDateString: arguments.startDate,
                                           endDateString: arguments.endDate)
    
    switch arguments.dataType.lowercased() {
    case "steps":
      return try await querySteps(startDate: startDate, endDate: endDate)
    case "heartrate":
      return try await queryHeartRate(startDate: startDate, endDate: endDate)
    case "workouts":
      return try await queryWorkouts(startDate: startDate, endDate: endDate)
    case "sleep":
      return try await querySleep(startDate: startDate, endDate: endDate)
    case "calories":
      return try await queryCalories(startDate: startDate, endDate: endDate)
    case "distance":
      return try await queryDistance(startDate: startDate, endDate: endDate)
    default:
      return createErrorOutput(error: HealthError.invalidDataType)
    }
  }
  
  private func requestHealthAuthorization(for dataType: String) async throws -> Bool {
    var readTypes: Set<HKObjectType> = []
    
    switch dataType.lowercased() {
    case "steps":
      readTypes.insert(HKQuantityType.quantityType(forIdentifier: .stepCount)!)
    case "heartrate":
      readTypes.insert(HKQuantityType.quantityType(forIdentifier: .heartRate)!)
    case "workouts":
      readTypes.insert(HKWorkoutType.workoutType())
    case "sleep":
      readTypes.insert(HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!)
    case "calories":
      readTypes.insert(HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!)
    case "distance":
      readTypes.insert(HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!)
    default:
      break
    }
    
    return try await withCheckedThrowingContinuation { continuation in
      healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
        if let error = error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume(returning: success)
        }
      }
    }
  }
  
  private func querySteps(startDate: Date, endDate: Date) async throws -> ToolOutput {
    guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
      return createErrorOutput(error: HealthError.invalidDataType)
    }
    
    let predicate = HKQuery.predicateForSamples(
      withStart: startDate,
      end: endDate,
      options: .strictStartDate
    )
    
    let query = HKStatisticsQuery(
      quantityType: stepType,
      quantitySamplePredicate: predicate,
      options: .cumulativeSum
    ) { _, statistics, error in
      // Handled in continuation below
    }
    
    return try await withCheckedThrowingContinuation { continuation in
      let query = HKStatisticsQuery(
        quantityType: stepType,
        quantitySamplePredicate: predicate,
        options: .cumulativeSum
      ) { _, statistics, error in
        if let error = error {
          continuation.resume(throwing: error)
          return
        }
        
        let stepCount = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
        
        let healthData = HealthData(
          dataType: "Steps",
          value: stepCount,
          unit: "count",
          startDate: self.dateFormatter.string(from: startDate),
          endDate: self.dateFormatter.string(from: endDate),
          samples: nil
        )
        
        continuation.resume(returning: self.createHealthSuccessOutput(data: [healthData]))
      }
      
      healthStore.execute(query)
    }
  }
  
  private func queryHeartRate(startDate: Date, endDate: Date) async throws -> ToolOutput {
    guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
      return createErrorOutput(error: HealthError.invalidDataType)
    }
    
    let predicate = HKQuery.predicateForSamples(
      withStart: startDate,
      end: endDate,
      options: .strictStartDate
    )
    
    return try await withCheckedThrowingContinuation { continuation in
      let query = HKSampleQuery(
        sampleType: heartRateType,
        predicate: predicate,
        limit: 100,
        sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
      ) { _, samples, error in
        if let error = error {
          continuation.resume(throwing: error)
          return
        }
        
        let heartRateSamples = (samples as? [HKQuantitySample]) ?? []
        
        let samples = heartRateSamples.map { sample in
          HealthSample(
            value: sample.quantity.doubleValue(for: HKUnit(from: "count/min")),
            date: self.dateFormatter.string(from: sample.startDate),
            source: sample.sourceRevision.source.name
          )
        }
        
        let avgHeartRate = samples.isEmpty ? 0 : samples.map { $0.value }.reduce(0, +) / Double(samples.count)
        
        let healthData = HealthData(
          dataType: "Heart Rate",
          value: avgHeartRate,
          unit: "bpm",
          startDate: self.dateFormatter.string(from: startDate),
          endDate: self.dateFormatter.string(from: endDate),
          samples: samples
        )
        
        continuation.resume(returning: self.createHealthSuccessOutput(data: [healthData]))
      }
      
      healthStore.execute(query)
    }
  }
  
  private func queryWorkouts(startDate: Date, endDate: Date) async throws -> ToolOutput {
    let workoutType = HKWorkoutType.workoutType()
    
    let predicate = HKQuery.predicateForSamples(
      withStart: startDate,
      end: endDate,
      options: .strictStartDate
    )
    
    return try await withCheckedThrowingContinuation { continuation in
      let query = HKSampleQuery(
        sampleType: workoutType,
        predicate: predicate,
        limit: 50,
        sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
      ) { _, samples, error in
        if let error = error {
          continuation.resume(throwing: error)
          return
        }
        
        let workouts = (samples as? [HKWorkout]) ?? []
        
        let workoutData = workouts.map { workout in
          WorkoutData(
            activityType: self.workoutActivityName(workout.workoutActivityType),
            duration: workout.duration,
            energyBurned: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()),
            distance: workout.totalDistance?.doubleValue(for: .meter()),
            startDate: self.dateFormatter.string(from: workout.startDate),
            endDate: self.dateFormatter.string(from: workout.endDate)
          )
        }
        
        continuation.resume(returning: self.createWorkoutSuccessOutput(workouts: workoutData))
      }
      
      healthStore.execute(query)
    }
  }
  
  private func querySleep(startDate: Date, endDate: Date) async throws -> ToolOutput {
    guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
      return createErrorOutput(error: HealthError.invalidDataType)
    }
    
    let predicate = HKQuery.predicateForSamples(
      withStart: startDate,
      end: endDate,
      options: .strictStartDate
    )
    
    return try await withCheckedThrowingContinuation { continuation in
      let query = HKSampleQuery(
        sampleType: sleepType,
        predicate: predicate,
        limit: HKObjectQueryNoLimit,
        sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
      ) { _, samples, error in
        if let error = error {
          continuation.resume(throwing: error)
          return
        }
        
        let sleepSamples = (samples as? [HKCategorySample]) ?? []
        
        var totalSleepTime: TimeInterval = 0
        
        for sample in sleepSamples {
          let sleepTime = sample.endDate.timeIntervalSince(sample.startDate)
          totalSleepTime += sleepTime
        }
        
        let healthData = HealthData(
          dataType: "Sleep",
          value: totalSleepTime / 3600, // Convert to hours
          unit: "hours",
          startDate: self.dateFormatter.string(from: startDate),
          endDate: self.dateFormatter.string(from: endDate),
          samples: nil
        )
        
        continuation.resume(returning: self.createHealthSuccessOutput(data: [healthData]))
      }
      
      healthStore.execute(query)
    }
  }
  
  private func queryCalories(startDate: Date, endDate: Date) async throws -> ToolOutput {
    guard let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
      return createErrorOutput(error: HealthError.invalidDataType)
    }
    
    let predicate = HKQuery.predicateForSamples(
      withStart: startDate,
      end: endDate,
      options: .strictStartDate
    )
    
    return try await withCheckedThrowingContinuation { continuation in
      let query = HKStatisticsQuery(
        quantityType: calorieType,
        quantitySamplePredicate: predicate,
        options: .cumulativeSum
      ) { _, statistics, error in
        if let error = error {
          continuation.resume(throwing: error)
          return
        }
        
        let calories = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
        
        let healthData = HealthData(
          dataType: "Active Calories",
          value: calories,
          unit: "kcal",
          startDate: self.dateFormatter.string(from: startDate),
          endDate: self.dateFormatter.string(from: endDate),
          samples: nil
        )
        
        continuation.resume(returning: self.createHealthSuccessOutput(data: [healthData]))
      }
      
      healthStore.execute(query)
    }
  }
  
  private func queryDistance(startDate: Date, endDate: Date) async throws -> ToolOutput {
    guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
      return createErrorOutput(error: HealthError.invalidDataType)
    }
    
    let predicate = HKQuery.predicateForSamples(
      withStart: startDate,
      end: endDate,
      options: .strictStartDate
    )
    
    return try await withCheckedThrowingContinuation { continuation in
      let query = HKStatisticsQuery(
        quantityType: distanceType,
        quantitySamplePredicate: predicate,
        options: .cumulativeSum
      ) { _, statistics, error in
        if let error = error {
          continuation.resume(throwing: error)
          return
        }
        
        let distance = statistics?.sumQuantity()?.doubleValue(for: .meter()) ?? 0
        
        let healthData = HealthData(
          dataType: "Walking/Running Distance",
          value: distance / 1000, // Convert to kilometers
          unit: "km",
          startDate: self.dateFormatter.string(from: startDate),
          endDate: self.dateFormatter.string(from: endDate),
          samples: nil
        )
        
        continuation.resume(returning: self.createHealthSuccessOutput(data: [healthData]))
      }
      
      healthStore.execute(query)
    }
  }
  
  private func getDateRange(from timeRange: String?, 
                           startDateString: String?, 
                           endDateString: String?) -> (start: Date, end: Date) {
    let calendar = Calendar.current
    let now = Date()
    
    // Check for custom date range first
    if let startString = startDateString,
       let endString = endDateString,
       let start = dateFormatter.date(from: startString),
       let end = dateFormatter.date(from: endString) {
      return (start, end)
    }
    
    // Use predefined time ranges
    switch timeRange?.lowercased() ?? "today" {
    case "today":
      let start = calendar.startOfDay(for: now)
      return (start, now)
    case "yesterday":
      let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
      let start = calendar.startOfDay(for: yesterday)
      let end = calendar.startOfDay(for: now)
      return (start, end)
    case "thisweek":
      let start = calendar.dateInterval(of: .weekOfYear, for: now)!.start
      return (start, now)
    case "lastweek":
      let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: now)!
      let interval = calendar.dateInterval(of: .weekOfYear, for: lastWeek)!
      return (interval.start, interval.end)
    case "thismonth":
      let start = calendar.dateInterval(of: .month, for: now)!.start
      return (start, now)
    default:
      // Default to today
      let start = calendar.startOfDay(for: now)
      return (start, now)
    }
  }
  
  private func workoutActivityName(_ type: HKWorkoutActivityType) -> String {
    switch type {
    case .running: return "Running"
    case .walking: return "Walking"
    case .cycling: return "Cycling"
    case .swimming: return "Swimming"
    case .yoga: return "Yoga"
    case .functionalStrengthTraining: return "Strength Training"
    case .traditionalStrengthTraining: return "Weight Training"
    case .coreTraining: return "Core Training"
    case .elliptical: return "Elliptical"
    case .rowing: return "Rowing"
    case .stairClimbing: return "Stair Climbing"
    case .hiking: return "Hiking"
    case .dance: return "Dance"
    default: return "Other Workout"
    }
  }
  
  private func createHealthSuccessOutput(data: [HealthData]) -> ToolOutput {
    var properties: [String: Any] = [
      "status": "success",
      "count": data.count
    ]
    
    properties["data"] = data.map { healthData in
      var dataDict: [String: Any] = [
        "type": healthData.dataType,
        "value": healthData.value,
        "unit": healthData.unit,
        "startDate": healthData.startDate,
        "endDate": healthData.endDate
      ]
      
      if let samples = healthData.samples, !samples.isEmpty {
        dataDict["samples"] = samples.map { sample in
          [
            "value": sample.value,
            "date": sample.date,
            "source": sample.source ?? "Unknown"
          ]
        }
      }
      
      return dataDict
    }
    
    return ToolOutput(GeneratedContent(properties: properties))
  }
  
  private func createWorkoutSuccessOutput(workouts: [WorkoutData]) -> ToolOutput {
    var properties: [String: Any] = [
      "status": "success",
      "count": workouts.count
    ]
    
    properties["workouts"] = workouts.map { workout in
      [
        "activityType": workout.activityType,
        "duration": workout.duration,
        "energyBurned": workout.energyBurned ?? 0,
        "distance": workout.distance ?? 0,
        "startDate": workout.startDate,
        "endDate": workout.endDate
      ]
    }
    
    return ToolOutput(GeneratedContent(properties: properties))
  }
  
  private func createErrorOutput(error: Error) -> ToolOutput {
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "error",
        "error": error.localizedDescription,
        "message": "Failed to query health data"
      ])
    )
  }
}

enum HealthError: Error, LocalizedError {
  case healthDataNotAvailable
  case authorizationDenied
  case invalidDataType
  
  var errorDescription: String? {
    switch self {
    case .healthDataNotAvailable:
      return "Health data is not available on this device."
    case .authorizationDenied:
      return "Authorization to access health data was denied. Please grant permission in Settings."
    case .invalidDataType:
      return "Invalid data type. Use 'steps', 'heartRate', 'workouts', 'sleep', 'calories', or 'distance'."
    }
  }
}
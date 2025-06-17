//
//  HealthTool.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/17/25.
//

import Foundation
import FoundationModels
import HealthKit

/// `HealthTool` provides access to health data from HealthKit.
///
/// This tool can read various health metrics like steps, heart rate, and workouts.
/// Important: This requires HealthKit entitlement and user permission.
struct HealthTool: Tool {
  
  /// The name of the tool, used for identification.
  let name = "accessHealth"
  /// A brief description of the tool's functionality.
  let description = "Read health data including steps, heart rate, workouts, and other metrics"
  
  /// Arguments for health data operations.
  @Generable
  struct Arguments {
    /// The type of health data to query: "steps", "heartRate", "workouts", "sleep", "activeEnergy", "distance"
    @Guide(description: "The type of health data to query: 'steps', 'heartRate', 'workouts', 'sleep', 'activeEnergy', 'distance'")
    var dataType: String
    
    /// Number of days to query (defaults to 7)
    @Guide(description: "Number of days to query (defaults to 7)")
    var daysBack: Int?
    
    /// Start date in ISO format (YYYY-MM-DD)
    @Guide(description: "Start date in ISO format (YYYY-MM-DD)")
    var startDate: String?
    
    /// End date in ISO format (YYYY-MM-DD)
    @Guide(description: "End date in ISO format (YYYY-MM-DD)")
    var endDate: String?
  }
  
  private let healthStore = HKHealthStore()
  
  func call(arguments: Arguments) async throws -> ToolOutput {
    // Check if HealthKit is available
    guard HKHealthStore.isHealthDataAvailable() else {
      return createErrorOutput(error: HealthError.healthKitNotAvailable)
    }
    
    switch arguments.dataType.lowercased() {
    case "steps":
      return await querySteps(arguments: arguments)
    case "heartrate":
      return await queryHeartRate(arguments: arguments)
    case "workouts":
      return await queryWorkouts(arguments: arguments)
    case "sleep":
      return await querySleep(arguments: arguments)
    case "activeenergy":
      return await queryActiveEnergy(arguments: arguments)
    case "distance":
      return await queryDistance(arguments: arguments)
    default:
      return createErrorOutput(error: HealthError.invalidDataType)
    }
  }
  
  private func querySteps(arguments: Arguments) async -> ToolOutput {
    guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
      return createErrorOutput(error: HealthError.dataTypeNotAvailable)
    }
    
    // Request authorization
    do {
      try await healthStore.requestAuthorization(toShare: [], read: [stepType])
    } catch {
      return createErrorOutput(error: HealthError.authorizationDenied)
    }
    
    let (startDate, endDate) = getDateRange(arguments: arguments)
    let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
    
    // Use async/await wrapper
    return await withCheckedContinuation { continuation in
      let query = HKStatisticsQuery(
        quantityType: stepType,
        quantitySamplePredicate: predicate,
        options: .cumulativeSum
      ) { _, result, error in
        if let error = error {
          continuation.resume(returning: self.createErrorOutput(error: error))
          return
        }
        
        guard let result = result,
              let sum = result.sumQuantity() else {
          continuation.resume(returning: self.createErrorOutput(error: HealthError.noData))
          return
        }
        
        let steps = sum.doubleValue(for: HKUnit.count())
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        continuation.resume(returning: ToolOutput(
          GeneratedContent(properties: [
            "status": "success",
            "dataType": "steps",
            "totalSteps": Int(steps),
            "startDate": dateFormatter.string(from: startDate),
            "endDate": dateFormatter.string(from: endDate),
            "dailyAverage": Int(steps / Double(self.daysBetween(start: startDate, end: endDate))),
            "message": "Total steps: \(Int(steps))"
          ])
        ))
      }
      
      healthStore.execute(query)
    }
  }
  
  private func queryHeartRate(arguments: Arguments) async -> ToolOutput {
    guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
      return createErrorOutput(error: HealthError.dataTypeNotAvailable)
    }
    
    // Request authorization
    do {
      try await healthStore.requestAuthorization(toShare: [], read: [heartRateType])
    } catch {
      return createErrorOutput(error: HealthError.authorizationDenied)
    }
    
    let (startDate, endDate) = getDateRange(arguments: arguments)
    let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
    
    return await withCheckedContinuation { continuation in
      let query = HKSampleQuery(
        sampleType: heartRateType,
        predicate: predicate,
        limit: 100,
        sortDescriptors: [sortDescriptor]
      ) { _, samples, error in
        if let error = error {
          continuation.resume(returning: self.createErrorOutput(error: error))
          return
        }
        
        guard let heartRateSamples = samples as? [HKQuantitySample], !heartRateSamples.isEmpty else {
          continuation.resume(returning: self.createErrorOutput(error: HealthError.noData))
          return
        }
        
        var heartRates: [Double] = []
        var latestReading = ""
        
        for (index, sample) in heartRateSamples.enumerated() {
          let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
          heartRates.append(heartRate)
          
          if index == 0 {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            latestReading = "\(Int(heartRate)) bpm at \(dateFormatter.string(from: sample.startDate))"
          }
        }
        
        let average = heartRates.reduce(0, +) / Double(heartRates.count)
        let min = heartRates.min() ?? 0
        let max = heartRates.max() ?? 0
        
        continuation.resume(returning: ToolOutput(
          GeneratedContent(properties: [
            "status": "success",
            "dataType": "heartRate",
            "latestReading": latestReading,
            "averageBPM": Int(average),
            "minBPM": Int(min),
            "maxBPM": Int(max),
            "sampleCount": heartRates.count,
            "message": "Average heart rate: \(Int(average)) bpm"
          ])
        ))
      }
      
      healthStore.execute(query)
    }
  }
  
  private func queryWorkouts(arguments: Arguments) async -> ToolOutput {
    let workoutType = HKObjectType.workoutType()
    
    // Request authorization
    do {
      try await healthStore.requestAuthorization(toShare: [], read: [workoutType])
    } catch {
      return createErrorOutput(error: HealthError.authorizationDenied)
    }
    
    let (startDate, endDate) = getDateRange(arguments: arguments)
    let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
    
    return await withCheckedContinuation { continuation in
      let query = HKSampleQuery(
        sampleType: workoutType,
        predicate: predicate,
        limit: 20,
        sortDescriptors: [sortDescriptor]
      ) { _, samples, error in
        if let error = error {
          continuation.resume(returning: self.createErrorOutput(error: error))
          return
        }
        
        guard let workouts = samples as? [HKWorkout], !workouts.isEmpty else {
          continuation.resume(returning: self.createErrorOutput(error: HealthError.noData))
          return
        }
        
        var workoutDescription = ""
        var totalDuration: TimeInterval = 0
        var totalCalories: Double = 0
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        for (index, workout) in workouts.enumerated() {
          let duration = workout.duration / 60 // Convert to minutes
          // Using deprecated API until replacement is available
          let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
          let distance = workout.totalDistance?.doubleValue(for: .meter()) ?? 0
          
          totalDuration += workout.duration
          totalCalories += calories
          
          workoutDescription += "\(index + 1). \(self.workoutActivityName(workout.workoutActivityType))\n"
          workoutDescription += "   Date: \(dateFormatter.string(from: workout.startDate))\n"
          workoutDescription += "   Duration: \(Int(duration)) minutes\n"
          if calories > 0 {
            workoutDescription += "   Calories: \(Int(calories))\n"
          }
          if distance > 0 {
            workoutDescription += "   Distance: \(String(format: "%.2f", distance / 1000)) km\n"
          }
          workoutDescription += "\n"
        }
        
        continuation.resume(returning: ToolOutput(
          GeneratedContent(properties: [
            "status": "success",
            "dataType": "workouts",
            "workoutCount": workouts.count,
            "totalDurationMinutes": Int(totalDuration / 60),
            "totalCalories": Int(totalCalories),
            "workouts": workoutDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            "message": "Found \(workouts.count) workout(s)"
          ])
        ))
      }
      
      healthStore.execute(query)
    }
  }
  
  private func querySleep(arguments: Arguments) async -> ToolOutput {
    guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
      return createErrorOutput(error: HealthError.dataTypeNotAvailable)
    }
    
    // Request authorization
    do {
      try await healthStore.requestAuthorization(toShare: [], read: [sleepType])
    } catch {
      return createErrorOutput(error: HealthError.authorizationDenied)
    }
    
    let (startDate, endDate) = getDateRange(arguments: arguments)
    let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
    
    return await withCheckedContinuation { continuation in
      let query = HKSampleQuery(
        sampleType: sleepType,
        predicate: predicate,
        limit: HKObjectQueryNoLimit,
        sortDescriptors: [sortDescriptor]
      ) { _, samples, error in
        if let error = error {
          continuation.resume(returning: self.createErrorOutput(error: error))
          return
        }
        
        guard let sleepSamples = samples as? [HKCategorySample], !sleepSamples.isEmpty else {
          continuation.resume(returning: self.createErrorOutput(error: HealthError.noData))
          return
        }
        
        var totalSleepTime: TimeInterval = 0
        var sleepDescription = ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        // Group sleep samples by day
        var sleepByDay: [Date: TimeInterval] = [:]
        
        for sample in sleepSamples {
          let duration = sample.endDate.timeIntervalSince(sample.startDate)
          totalSleepTime += duration
          
          let calendar = Calendar.current
          let day = calendar.startOfDay(for: sample.startDate)
          sleepByDay[day, default: 0] += duration
        }
        
        for (day, duration) in sleepByDay.sorted(by: { $0.key > $1.key }).prefix(7) {
          let hours = duration / 3600
          sleepDescription += "\(dateFormatter.string(from: day)): \(String(format: "%.1f", hours)) hours\n"
        }
        
        let avgSleepHours = (totalSleepTime / Double(sleepByDay.count)) / 3600
        
        continuation.resume(returning: ToolOutput(
          GeneratedContent(properties: [
            "status": "success",
            "dataType": "sleep",
            "averageSleepHours": String(format: "%.1f", avgSleepHours),
            "totalNights": sleepByDay.count,
            "sleepData": sleepDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            "message": "Average sleep: \(String(format: "%.1f", avgSleepHours)) hours per night"
          ])
        ))
      }
      
      healthStore.execute(query)
    }
  }
  
  private func queryActiveEnergy(arguments: Arguments) async -> ToolOutput {
    guard let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
      return createErrorOutput(error: HealthError.dataTypeNotAvailable)
    }
    
    // Request authorization
    do {
      try await healthStore.requestAuthorization(toShare: [], read: [energyType])
    } catch {
      return createErrorOutput(error: HealthError.authorizationDenied)
    }
    
    let (startDate, endDate) = getDateRange(arguments: arguments)
    let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
    
    return await withCheckedContinuation { continuation in
      let query = HKStatisticsQuery(
        quantityType: energyType,
        quantitySamplePredicate: predicate,
        options: .cumulativeSum
      ) { _, result, error in
        if let error = error {
          continuation.resume(returning: self.createErrorOutput(error: error))
          return
        }
        
        guard let result = result,
              let sum = result.sumQuantity() else {
          continuation.resume(returning: self.createErrorOutput(error: HealthError.noData))
          return
        }
        
        let calories = sum.doubleValue(for: .kilocalorie())
        let days = self.daysBetween(start: startDate, end: endDate)
        let dailyAverage = calories / Double(days)
        
        continuation.resume(returning: ToolOutput(
          GeneratedContent(properties: [
            "status": "success",
            "dataType": "activeEnergy",
            "totalCalories": Int(calories),
            "dailyAverage": Int(dailyAverage),
            "startDate": self.formatDate(startDate),
            "endDate": self.formatDate(endDate),
            "message": "Total active energy: \(Int(calories)) calories"
          ])
        ))
      }
      
      healthStore.execute(query)
    }
  }
  
  private func queryDistance(arguments: Arguments) async -> ToolOutput {
    guard let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) else {
      return createErrorOutput(error: HealthError.dataTypeNotAvailable)
    }
    
    // Request authorization
    do {
      try await healthStore.requestAuthorization(toShare: [], read: [distanceType])
    } catch {
      return createErrorOutput(error: HealthError.authorizationDenied)
    }
    
    let (startDate, endDate) = getDateRange(arguments: arguments)
    let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
    
    return await withCheckedContinuation { continuation in
      let query = HKStatisticsQuery(
        quantityType: distanceType,
        quantitySamplePredicate: predicate,
        options: .cumulativeSum
      ) { _, result, error in
        if let error = error {
          continuation.resume(returning: self.createErrorOutput(error: error))
          return
        }
        
        guard let result = result,
              let sum = result.sumQuantity() else {
          continuation.resume(returning: self.createErrorOutput(error: HealthError.noData))
          return
        }
        
        let meters = sum.doubleValue(for: .meter())
        let kilometers = meters / 1000
        let miles = meters / 1609.344
        let days = self.daysBetween(start: startDate, end: endDate)
        let dailyAverage = kilometers / Double(days)
        
        continuation.resume(returning: ToolOutput(
          GeneratedContent(properties: [
            "status": "success",
            "dataType": "distance",
            "totalKilometers": String(format: "%.2f", kilometers),
            "totalMiles": String(format: "%.2f", miles),
            "dailyAverageKm": String(format: "%.2f", dailyAverage),
            "startDate": self.formatDate(startDate),
            "endDate": self.formatDate(endDate),
            "message": "Total distance: \(String(format: "%.2f", kilometers)) km"
          ])
        ))
      }
      
      healthStore.execute(query)
    }
  }
  
  private func getDateRange(arguments: Arguments) -> (Date, Date) {
    let calendar = Calendar.current
    let endDate = Date()
    
    if let startDateString = arguments.startDate,
       let parsedStartDate = parseDate(startDateString) {
      let parsedEndDate = arguments.endDate.flatMap { parseDate($0) } ?? endDate
      return (parsedStartDate, parsedEndDate)
    }
    
    let daysBack = arguments.daysBack ?? 7
    let startDate = calendar.date(byAdding: .day, value: -daysBack, to: endDate) ?? endDate
    return (startDate, endDate)
  }
  
  private func parseDate(_ dateString: String) -> Date? {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone.current
    return formatter.date(from: dateString)
  }
  
  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
  }
  
  private func daysBetween(start: Date, end: Date) -> Int {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.day], from: start, to: end)
    return max(1, components.day ?? 1)
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
    case .pilates: return "Pilates"
    default: return "Other Workout"
    }
  }
  
  private func createErrorOutput(error: Error) -> ToolOutput {
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "error",
        "error": error.localizedDescription,
        "message": "Failed to access health data"
      ])
    )
  }
}

enum HealthError: Error, LocalizedError {
  case healthKitNotAvailable
  case authorizationDenied
  case invalidDataType
  case dataTypeNotAvailable
  case noData
  
  var errorDescription: String? {
    switch self {
    case .healthKitNotAvailable:
      return "HealthKit is not available on this device."
    case .authorizationDenied:
      return "Access to health data denied. Please grant permission in Settings."
    case .invalidDataType:
      return "Invalid data type. Use 'steps', 'heartRate', 'workouts', 'sleep', 'activeEnergy', or 'distance'."
    case .dataTypeNotAvailable:
      return "This health data type is not available."
    case .noData:
      return "No health data found for the specified period."
    }
  }
}
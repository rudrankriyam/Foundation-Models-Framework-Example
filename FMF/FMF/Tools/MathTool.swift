//
//  MathTool.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/17/25.
//

import Foundation
import FoundationModels

/// `MathTool` provides mathematical calculations and operations.
///
/// This tool can perform various mathematical operations including statistics and conversions.
struct MathTool: Tool {
  
  /// The name of the tool, used for identification.
  let name = "calculate"
  /// A brief description of the tool's functionality.
  let description = "Perform mathematical calculations, statistics, and unit conversions"
  
  /// Arguments for math operations.
  @Generable
  struct Arguments {
    /// The operation to perform: "basic", "statistics", "convert"
    @Guide(description: "The operation to perform: 'basic', 'statistics', 'convert'")
    var operation: String
    
    /// Type of calculation: "add", "subtract", "multiply", "divide", "power", "sqrt"
    @Guide(description: "Type of calculation: 'add', 'subtract', 'multiply', 'divide', 'power', 'sqrt'")
    var calculationType: String?
    
    /// First number for calculation
    @Guide(description: "First number for calculation")
    var number1: Double?
    
    /// Second number for calculation
    @Guide(description: "Second number for calculation")
    var number2: Double?
    
    /// Array of numbers as comma-separated string (for statistics)
    @Guide(description: "Array of numbers as comma-separated string (for statistics)")
    var numbers: String?
    
    /// Unit conversion type: "temperature", "length", "weight"
    @Guide(description: "Unit conversion type: 'temperature', 'length', 'weight'")
    var conversionType: String?
    
    /// Value to convert
    @Guide(description: "Value to convert")
    var value: Double?
    
    /// From unit (e.g., "celsius", "meters", "pounds")
    @Guide(description: "From unit (e.g., 'celsius', 'meters', 'pounds')")
    var fromUnit: String?
    
    /// To unit (e.g., "fahrenheit", "feet", "kilograms")
    @Guide(description: "To unit (e.g., 'fahrenheit', 'feet', 'kilograms')")
    var toUnit: String?
  }
  
  func call(arguments: Arguments) async throws -> ToolOutput {
    switch arguments.operation.lowercased() {
    case "basic":
      return performBasicCalculation(arguments: arguments)
    case "statistics":
      return calculateStatistics(arguments: arguments)
    case "convert":
      return performConversion(arguments: arguments)
    default:
      return createErrorOutput(error: MathError.invalidOperation)
    }
  }
  
  private func performBasicCalculation(arguments: Arguments) -> ToolOutput {
    guard let type = arguments.calculationType else {
      return createErrorOutput(error: MathError.missingCalculationType)
    }
    
    let result: Double
    
    switch type.lowercased() {
    case "add":
      guard let n1 = arguments.number1, let n2 = arguments.number2 else {
        return createErrorOutput(error: MathError.missingNumbers)
      }
      result = n1 + n2
      
    case "subtract":
      guard let n1 = arguments.number1, let n2 = arguments.number2 else {
        return createErrorOutput(error: MathError.missingNumbers)
      }
      result = n1 - n2
      
    case "multiply":
      guard let n1 = arguments.number1, let n2 = arguments.number2 else {
        return createErrorOutput(error: MathError.missingNumbers)
      }
      result = n1 * n2
      
    case "divide":
      guard let n1 = arguments.number1, let n2 = arguments.number2 else {
        return createErrorOutput(error: MathError.missingNumbers)
      }
      guard n2 != 0 else {
        return createErrorOutput(error: MathError.divisionByZero)
      }
      result = n1 / n2
      
    case "power":
      guard let n1 = arguments.number1, let n2 = arguments.number2 else {
        return createErrorOutput(error: MathError.missingNumbers)
      }
      result = pow(n1, n2)
      
    case "sqrt":
      guard let n1 = arguments.number1 else {
        return createErrorOutput(error: MathError.missingNumbers)
      }
      guard n1 >= 0 else {
        return createErrorOutput(error: MathError.negativeSquareRoot)
      }
      result = sqrt(n1)
      
    default:
      return createErrorOutput(error: MathError.invalidCalculationType)
    }
    
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "success",
        "operation": type,
        "number1": arguments.number1 ?? 0,
        "number2": arguments.number2 ?? 0,
        "result": result,
        "formattedResult": formatNumber(result)
      ])
    )
  }
  
  private func calculateStatistics(arguments: Arguments) -> ToolOutput {
    guard let numbersString = arguments.numbers else {
      return createErrorOutput(error: MathError.missingNumbers)
    }
    
    let numbers = numbersString.split(separator: ",")
      .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
    
    guard !numbers.isEmpty else {
      return createErrorOutput(error: MathError.invalidNumberFormat)
    }
    
    let sum = numbers.reduce(0, +)
    let mean = sum / Double(numbers.count)
    let sortedNumbers = numbers.sorted()
    
    let median: Double
    if numbers.count % 2 == 0 {
      median = (sortedNumbers[numbers.count / 2 - 1] + sortedNumbers[numbers.count / 2]) / 2
    } else {
      median = sortedNumbers[numbers.count / 2]
    }
    
    let variance = numbers.reduce(0) { $0 + pow($1 - mean, 2) } / Double(numbers.count)
    let standardDeviation = sqrt(variance)
    
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "success",
        "count": numbers.count,
        "sum": sum,
        "mean": mean,
        "median": median,
        "min": sortedNumbers.first ?? 0,
        "max": sortedNumbers.last ?? 0,
        "standardDeviation": standardDeviation,
        "variance": variance
      ])
    )
  }
  
  private func performConversion(arguments: Arguments) -> ToolOutput {
    guard let type = arguments.conversionType,
          let value = arguments.value,
          let fromUnit = arguments.fromUnit,
          let toUnit = arguments.toUnit else {
      return createErrorOutput(error: MathError.missingConversionParameters)
    }
    
    let result: Double
    
    switch type.lowercased() {
    case "temperature":
      result = convertTemperature(value: value, from: fromUnit, to: toUnit)
    case "length":
      result = convertLength(value: value, from: fromUnit, to: toUnit)
    case "weight":
      result = convertWeight(value: value, from: fromUnit, to: toUnit)
    default:
      return createErrorOutput(error: MathError.invalidConversionType)
    }
    
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "success",
        "conversionType": type,
        "originalValue": value,
        "fromUnit": fromUnit,
        "toUnit": toUnit,
        "convertedValue": result,
        "formattedResult": "\(formatNumber(value)) \(fromUnit) = \(formatNumber(result)) \(toUnit)"
      ])
    )
  }
  
  private func convertTemperature(value: Double, from: String, to: String) -> Double {
    // Convert to Celsius first
    let celsius: Double
    switch from.lowercased() {
    case "celsius", "c":
      celsius = value
    case "fahrenheit", "f":
      celsius = (value - 32) * 5/9
    case "kelvin", "k":
      celsius = value - 273.15
    default:
      return value
    }
    
    // Convert from Celsius to target
    switch to.lowercased() {
    case "celsius", "c":
      return celsius
    case "fahrenheit", "f":
      return celsius * 9/5 + 32
    case "kelvin", "k":
      return celsius + 273.15
    default:
      return value
    }
  }
  
  private func convertLength(value: Double, from: String, to: String) -> Double {
    // Convert to meters first
    let meters: Double
    switch from.lowercased() {
    case "meters", "m":
      meters = value
    case "kilometers", "km":
      meters = value * 1000
    case "feet", "ft":
      meters = value * 0.3048
    case "miles", "mi":
      meters = value * 1609.344
    case "inches", "in":
      meters = value * 0.0254
    default:
      return value
    }
    
    // Convert from meters to target
    switch to.lowercased() {
    case "meters", "m":
      return meters
    case "kilometers", "km":
      return meters / 1000
    case "feet", "ft":
      return meters / 0.3048
    case "miles", "mi":
      return meters / 1609.344
    case "inches", "in":
      return meters / 0.0254
    default:
      return value
    }
  }
  
  private func convertWeight(value: Double, from: String, to: String) -> Double {
    // Convert to kilograms first
    let kilograms: Double
    switch from.lowercased() {
    case "kilograms", "kg":
      kilograms = value
    case "grams", "g":
      kilograms = value / 1000
    case "pounds", "lbs", "lb":
      kilograms = value * 0.453592
    case "ounces", "oz":
      kilograms = value * 0.0283495
    default:
      return value
    }
    
    // Convert from kilograms to target
    switch to.lowercased() {
    case "kilograms", "kg":
      return kilograms
    case "grams", "g":
      return kilograms * 1000
    case "pounds", "lbs", "lb":
      return kilograms / 0.453592
    case "ounces", "oz":
      return kilograms / 0.0283495
    default:
      return value
    }
  }
  
  private func formatNumber(_ number: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 6
    formatter.minimumFractionDigits = 0
    return formatter.string(from: NSNumber(value: number)) ?? String(number)
  }
  
  private func createErrorOutput(error: Error) -> ToolOutput {
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "error",
        "error": error.localizedDescription,
        "message": "Failed to perform calculation"
      ])
    )
  }
}

enum MathError: Error, LocalizedError {
  case invalidOperation
  case missingCalculationType
  case missingNumbers
  case divisionByZero
  case negativeSquareRoot
  case invalidCalculationType
  case invalidNumberFormat
  case missingConversionParameters
  case invalidConversionType
  
  var errorDescription: String? {
    switch self {
    case .invalidOperation:
      return "Invalid operation. Use 'basic', 'statistics', or 'convert'."
    case .missingCalculationType:
      return "Calculation type is required for basic operations."
    case .missingNumbers:
      return "Required numbers are missing."
    case .divisionByZero:
      return "Cannot divide by zero."
    case .negativeSquareRoot:
      return "Cannot calculate square root of negative number."
    case .invalidCalculationType:
      return "Invalid calculation type."
    case .invalidNumberFormat:
      return "Invalid number format in the provided list."
    case .missingConversionParameters:
      return "Missing required conversion parameters."
    case .invalidConversionType:
      return "Invalid conversion type. Use 'temperature', 'length', or 'weight'."
    }
  }
}
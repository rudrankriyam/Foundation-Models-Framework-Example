//
//  ModelAvailabilityView.swift
//  FoundationLab
//
//  Created by Claude on 1/29/25.
//

import FoundationModels
import SwiftUI

struct ModelAvailabilityView: View {
  @State private var availabilityStatus = "Tap 'Check Availability' to verify Apple Intelligence status"
  @State private var isChecking = false
  @State private var isAvailable: Bool?
  
  var body: some View {
    ExampleViewBase(
      title: "Model Availability",
      icon: "checkmark.shield",
      description: "Check if Apple Intelligence is available on this device",
      defaultPrompt: DefaultPrompts.modelAvailability,
      currentPrompt: .constant(DefaultPrompts.modelAvailability),
      isRunning: isChecking,
      errorMessage: nil,
      codeExample: DefaultPrompts.modelAvailabilityCode,
      onRun: checkAvailability,
      onReset: resetStatus
    ) {
      VStack(spacing: 16) {
        // Status Card
        VStack(spacing: 12) {
          Image(systemName: isAvailable == true ? "checkmark.circle.fill" : isAvailable == false ? "xmark.circle.fill" : "questionmark.circle")
            .font(.system(size: 60))
            .foregroundColor(isAvailable == true ? .green : isAvailable == false ? .red : .gray)
          
          Text(availabilityStatus)
            .font(.body)
            .multilineTextAlignment(.center)
            .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(Color.secondaryBackgroundColor)
        .cornerRadius(12)
        
        // Info Section
        VStack(alignment: .leading, spacing: 12) {
          Label("Requirements", systemImage: "info.circle")
            .font(.headline)
          
          VStack(alignment: .leading, spacing: 8) {
            RequirementRow(
              icon: "iphone",
              text: "Compatible Apple device with Apple Silicon",
              isMet: isAvailable
            )
            
            RequirementRow(
              icon: "gear",
              text: "iOS 26.0+ or macOS 26.0+",
              isMet: isAvailable
            )
            
            RequirementRow(
              icon: "brain",
              text: "Apple Intelligence enabled in Settings",
              isMet: isAvailable
            )
          }
        }
        .padding()
        .background(Color.secondaryBackgroundColor)
        .cornerRadius(8)
      }
    }
  }
  
  private func checkAvailability() {
    Task {
      isChecking = true
      isAvailable = nil
      
      let availability = SystemLanguageModel.default.availability
      
      if availability == .available {
        isAvailable = true
        availabilityStatus = "✅ Apple Intelligence is available and ready to use!"
      } else {
        isAvailable = false
        availabilityStatus = "❌ Apple Intelligence is not available on this device. This feature requires iOS 26.0+ or macOS 26.0+ and a compatible Apple device with Apple Intelligence enabled."
      }
      
      isChecking = false
    }
  }
  
  private func resetStatus() {
    availabilityStatus = "Tap 'Check Availability' to verify Apple Intelligence status"
    isAvailable = nil
  }
}

// MARK: - Supporting Views

private struct RequirementRow: View {
  let icon: String
  let text: String
  let isMet: Bool?
  
  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .foregroundColor(isMet == true ? .green : isMet == false ? .red : .secondary)
        .frame(width: 24)
      
      Text(text)
        .font(.subheadline)
        .foregroundColor(.primary)
      
      Spacer()
      
      if let isMet = isMet {
        Image(systemName: isMet ? "checkmark" : "xmark")
          .foregroundColor(isMet ? .green : .red)
          .font(.caption)
      }
    }
  }
}

#Preview {
  NavigationStack {
    ModelAvailabilityView()
  }
}
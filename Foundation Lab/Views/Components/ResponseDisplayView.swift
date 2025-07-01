//
//  ResponseDisplayView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/9/25.
//

import FoundationModels
import SwiftUI

/// View component for displaying AI model requests and responses
struct ResponseDisplayView: View {
  let requestResponse: RequestResponsePair
  let onClear: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      headerView
      requestView
      responseView
    }
  }

  private var headerView: some View {
    HStack {
      VStack(alignment: .leading, spacing: 2) {
        Text("Request & Response")
          .font(.headline)
        Text(requestResponse.timestamp.formatted(date: .omitted, time: .shortened))
          .font(.caption2)
          .foregroundStyle(.secondary)
      }

      Spacer()

      Button("Clear", action: onClear)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .padding(.horizontal)
  }

  private var requestView: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Request")
        .font(.subheadline)
        .fontWeight(.medium)
      
      ScrollView {
        Text(requestResponse.request)
          .font(.system(.body, design: .default))
          .padding()
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(requestBackgroundView)
          .foregroundColor(.primary)
          .textSelection(.enabled)
      }
      .frame(maxHeight: 100)
    }
    .padding(.horizontal)
  }
  
  private var responseView: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        if requestResponse.isError {
          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundStyle(.red)
        }
        Text("Response")
          .font(.subheadline)
          .fontWeight(.medium)
      }
      
      ScrollView {
        Text(requestResponse.response)
          .font(.system(.body, design: .monospaced))
          .padding()
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(responseBackgroundView)
          .foregroundColor(responseTextColor)
          .textSelection(.enabled)
      }
    }
    .padding(.horizontal)
  }

  private var requestBackgroundView: some View {
    RoundedRectangle(cornerRadius: 8)
      .fill(Color.main.opacity(0.1))
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(Color.main.opacity(0.2), lineWidth: 1)
      )
  }
  
  private var responseBackgroundView: some View {
    RoundedRectangle(cornerRadius: 8)
      .fill(responseBackgroundColor)
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(responseBorderColor, lineWidth: 1)
      )
  }

  private var responseBackgroundColor: Color {
    requestResponse.isError ? Color.red.opacity(0.1) : Color.green.opacity(0.1)
  }

  private var responseBorderColor: Color {
    requestResponse.isError ? Color.red.opacity(0.3) : Color.green.opacity(0.2)
  }

  private var responseTextColor: Color {
    requestResponse.isError ? .red : .primary
  }
}

#Preview {
  VStack(spacing: 20) {
    ResponseDisplayView(
      requestResponse: RequestResponsePair(
        request: "Suggest a catchy name for a new coffee shop.",
        response: "Here are some catchy coffee shop names:\n\n• Bean There, Done That\n• Grounds for Celebration\n• The Daily Grind\n• Espresso Yourself\n• Caffeine & Company"
      ),
      onClear: {}
    )

    ResponseDisplayView(
      requestResponse: RequestResponsePair(
        request: "Generate a business plan for a startup.",
        response: "This is an error message that would be displayed when something goes wrong with the AI model.",
        isError: true
      ),
      onClear: {}
    )
  }
  .padding()
}

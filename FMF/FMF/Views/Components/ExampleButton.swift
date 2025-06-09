//
//  ExampleButton.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/9/25.
//

import FoundationModels
import SwiftUI

/// Reusable button component for example actions
struct ExampleButton: View {
  let title: String
  let subtitle: String
  let icon: String
  let action: () async -> Void

  @State private var isPressed = false

  var body: some View {
    Button {
      Task {
        await action()
      }
    } label: {
      buttonContent
    }
    .buttonStyle(PlainButtonStyle())
    .scaleEffect(isPressed ? 0.98 : 1.0)
    .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) {
      withAnimation(.easeInOut(duration: 0.1)) {
        isPressed = true
      }
    } onPressingChanged: { pressing in
      if !pressing {
        withAnimation(.easeInOut(duration: 0.1)) {
          isPressed = false
        }
      }
    }
  }

  private var buttonContent: some View {
    HStack(spacing: 12) {
      iconView
      textContent
      Spacer()
      chevronIcon
    }
    .padding()
    .background(backgroundView)
  }

  private var iconView: some View {
    Image(systemName: icon)
      .font(.title2)
      .foregroundStyle(.tint)
      .frame(width: 30)
  }

  private var textContent: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(title)
        .font(.headline)
        .foregroundStyle(.primary)
      Text(subtitle)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }

  private var chevronIcon: some View {
    Image(systemName: "chevron.right")
      .font(.caption)
      .foregroundStyle(.tertiary)
  }

  private var backgroundView: some View {
    RoundedRectangle(cornerRadius: 12)
      .fill(Color.gray.opacity(0.1))
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
      )
  }
}

#Preview {
  VStack(spacing: 12) {
    ExampleButton(
      title: "Basic Chat",
      subtitle: "Simple conversation with the model",
      icon: "message"
    ) {
      // Preview action
    }

    ExampleButton(
      title: "Tool Calling",
      subtitle: "Use custom tools with the model",
      icon: "wrench.and.screwdriver"
    ) {
      // Preview action
    }
  }
  .padding()
}

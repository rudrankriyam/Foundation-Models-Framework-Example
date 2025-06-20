//
//  ExampleButton.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/9/25.
//

import FoundationModels
import SwiftUI

/// Reusable button component for example actions with Liquid Glass effects
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
    #if os(iOS)
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        iconView
        Spacer()
        chevronIcon
      }
      textContent
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    #else
    HStack(spacing: 12) {
      iconView
      textContent
      Spacer()
      chevronIcon
    }
    .padding()
    #endif
  }

  private var iconView: some View {
    Image(systemName: icon)
      .font(.title2)
      .foregroundStyle(.tint)
      .frame(width: 30)
  }

  private var textContent: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(titleFont)
        .fontWeight(.medium)
        .foregroundStyle(.primary)
        .fixedSize(horizontal: false, vertical: true)
      Text(subtitle)
        .font(subtitleFont)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
        .lineLimit(nil)
    }
  }

  private var titleFont: Font {
    #if os(iOS)
    .subheadline
    #else
    .headline
    #endif
  }

  private var subtitleFont: Font {
    #if os(iOS)
    .caption
    #else
    .caption
    #endif
  }

  private var chevronIcon: some View {
    Image(systemName: "chevron.right")
      .font(.caption)
      .foregroundStyle(.tertiary)
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
    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))

    ExampleButton(
      title: "Tool Calling",
      subtitle: "Use custom tools with the model",
      icon: "wrench.and.screwdriver"
    ) {
      // Preview action
    }
    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
  }
  .padding()
}

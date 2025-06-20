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
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        iconView
        Spacer()
        chevronIcon
      }

      VStack(alignment: .leading, spacing: 6) {
        titleText
        subtitleText
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .frame(minHeight: buttonMinHeight)
    .padding(16)
    .scaleEffect(isPressed ? 0.98 : 1.0)
    .animation(.easeInOut(duration: 0.15), value: isPressed)
    #else
    HStack(spacing: 12) {
      iconView

      VStack(alignment: .leading, spacing: 4) {
        titleText
        subtitleText
      }

      Spacer()
      chevronIcon
    }
    .frame(minHeight: buttonMinHeight)
    .padding(16)
    .scaleEffect(isPressed ? 0.98 : 1.0)
    .animation(.easeInOut(duration: 0.15), value: isPressed)
    #endif
  }

  private var iconView: some View {
    Image(systemName: icon)
      .font(.title2)
      .foregroundStyle(.tint)
      .frame(width: 24, height: 24)
  }

  private var titleText: some View {
    Text(title)
      .font(.subheadline)
      .fontWeight(.medium)
      .foregroundStyle(.primary)
      .lineLimit(2)
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var subtitleText: some View {
    Text(subtitle)
      .font(.caption)
      .foregroundStyle(.secondary)
      .lineLimit(1)
      .truncationMode(.tail)
      .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var chevronIcon: some View {
    Image(systemName: "chevron.right")
      .font(.caption)
      .foregroundStyle(.tertiary)
  }

  private var buttonMinHeight: CGFloat {
    #if os(iOS)
    85
    #else
    70
    #endif
  }
}

#Preview {
  VStack(spacing: 12) {
    ExampleButton(
      title: "Basic Chat",
      subtitle: "Simple conversation with AI",
      icon: "message"
    ) {
      // Preview action
    }
    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))

    ExampleButton(
      title: "Creative Writing",
      subtitle: "Generate stories and content",
      icon: "pencil.and.outline"
    ) {
      // Preview action
    }
    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))

    ExampleButton(
      title: "Business Ideas",
      subtitle: "Generate startup concepts",
      icon: "lightbulb"
    ) {
      // Preview action
    }
    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
  }
  .padding()
}

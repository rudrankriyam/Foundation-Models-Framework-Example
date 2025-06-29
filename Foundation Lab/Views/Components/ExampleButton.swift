//
//  ExampleButton.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/9/25.
//

import FoundationModels
import SwiftUI

/// Reusable button component for example actions with Liquid Glass effects
struct ExampleButton: View {
    let exampleType: ExampleType
    let action: () async -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            Task {
                await action()
            }
        } label: {
            ExampleCardView(type: exampleType)
                .pressed(isPressed)
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
}

struct ExampleCardView: View {
    let type: ExampleType

    var body: some View {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .frame(minHeight: buttonMinHeight)
        .padding(16)
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: buttonMinHeight)
        .padding(16)
#endif
    }

    private var iconView: some View {
        Image(systemName: type.icon)
            .font(.title2)
            .foregroundStyle(.tint)
            .frame(width: 24, height: 24)
    }

    private var titleText: some View {
        Text(type.title)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.primary)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var subtitleText: some View {
        Text(type.subtitle)
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
        return 85
#else
        return 70
#endif
    }

    func pressed(_ isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
    }
}

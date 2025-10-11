//
//  GlassDropdown.swift
//  Murmer
//
//  Created by Rudrank Riyam on 6/26/25.
//

import SwiftUI

struct GlassDropdown: View {
    @Binding var selectedValue: String
    let options: [String]
    let title: String

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(selectedValue)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Dropdown content
            if isExpanded {
                Divider()
                    .background(Color.primary.opacity(0.1))

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(options, id: \.self) { option in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedValue = option
                                    isExpanded = false
                                }

                                // Haptic feedback
                                #if os(iOS)
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                #endif
                            }) {
                                HStack {
                                    Text(option)
                                        .font(.body)
                                        .foregroundStyle(selectedValue == option ? .primary : .secondary)

                                    Spacer()

                                    if selectedValue == option {
                                        Image(systemName: "checkmark")
                                            .font(.caption)
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .padding()
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if option != options.last {
                                Divider()
                                    .background(Color.primary.opacity(0.05))
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                #if os(iOS) || os(macOS)
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
                #endif
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

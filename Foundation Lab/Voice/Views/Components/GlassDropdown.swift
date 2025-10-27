//
//  GlassDropdown.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 10/27/25.
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
            }, label: {
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
            })
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

                                #if os(iOS)
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                #endif
                            }, label: {
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
                            })
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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    @Previewable @State var selectedOption = "Option 1"
    let options = ["Option 1", "Option 2", "Option 3", "Option 4"]

    GlassDropdown(selectedValue: $selectedOption, options: options, title: "Choose an option")
        .padding()
        .frame(width: 300)
}
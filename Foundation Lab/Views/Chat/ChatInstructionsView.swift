//
//  ChatInstructionsView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI

struct ChatInstructionsView: View {
    enum Constants {
        static let defaultTopKValue = 50
        static let topKMinValue = 1
        static let topKMaxValue = 100
        static let textFieldWidth: CGFloat = 100
        static let samplingConfigBackgroundColor = Color.blue.opacity(0.05)
    }
    @Binding var viewModel: ChatViewModel

    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss

    @Namespace private var glassNamespace

    private var clampedTopKSamplingValue: Binding<Int> {
        Binding(
            get: { viewModel.topKSamplingValue },
            set: { viewModel.topKSamplingValue = min(Constants.topKMaxValue, max(Constants.topKMinValue, $0)) }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.large) {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Customize AI Behavior")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Provide specific instructions to guide how the AI should respond. These instructions will " +
                             "apply to all new conversations.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }

                    samplingStrategySection

                    // Guardrails Toggle
                    PermissiveGuardrailsToggle(isEnabled: $viewModel.usePermissiveGuardrails)

                    TextEditor(text: $viewModel.instructions)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .padding(Spacing.medium)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )

                    Spacer(minLength: 20)
                }
                .padding(Spacing.medium)
            }
            .navigationTitle("Instructions")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var samplingStrategySection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Sampling Strategy")
                .font(.headline)
                .padding(.horizontal, Spacing.medium)

            Picker("Sampling Strategy", selection: $viewModel.samplingStrategy) {
                Text("Default").tag(SamplingStrategy.default)
                Text("Greedy").tag(SamplingStrategy.greedy)
                Text("Sampling").tag(SamplingStrategy.sampling)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.medium)

            Text("""
                Default: Uses system defaults for optimal balance.
                Greedy: Always chooses the most likely token (deterministic).
                Sampling: Uses top-k sampling for creative, varied responses.
                """)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Spacing.medium)

            if viewModel.samplingStrategy == .sampling {
                samplingConfigurationView
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, Spacing.small)
            }
        }
        .padding(Spacing.medium)
        .glassEffect(.regular.interactive(true), in: .rect(cornerRadius: 12))
        .glassEffectID("sampling-strategy", in: glassNamespace)
    }

    private var samplingConfigurationView: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack {
                Text("Top-K Sampling Value")
                    .font(.subheadline)
                Spacer()
                TextField("Value", value: clampedTopKSamplingValue, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .frame(width: Constants.textFieldWidth)
            }

            Toggle("Use Fixed Seed", isOn: $viewModel.useFixedSeed)
                .font(.subheadline)

            Text("The Top-K value determines how many of the most likely tokens to consider. " +
                 "Lower values (10-20) produce more focused, deterministic responses. " +
                 "Higher values (50-100) allow more creative variations.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if viewModel.useFixedSeed {
                HStack {
                    Image(systemName: "dice")
                        .foregroundColor(.secondary)
                    Text("Using fixed seed for reproducible variations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, Spacing.small)
            }
        }
        .padding(Spacing.medium)
        .background(Constants.samplingConfigBackgroundColor)
        .cornerRadius(12)
    }
}

#Preview {
    ChatInstructionsView(viewModel: .constant(.init()),
        onApply: { }
    )
}

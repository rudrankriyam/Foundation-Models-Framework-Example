//
//  ChatInstructionsView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI

enum SamplingStrategy: Int, CaseIterable {
    case `default`
    case greedy
    case sampling
}

struct ChatInstructionsView: View {
    @Binding var instructions: String
    @Binding var useGreedySampling: Bool
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selectedStrategy: SamplingStrategy = .default
    @State private var topKSamplingValue: Int = 50
    @State private var useRandomSeed: Bool = false
    @Namespace private var glassNamespace

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

                    TextEditor(text: $instructions)
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
                        updateGreedySamplingFromStrategy()
                        onApply()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadStrategyFromGreedySampling()
        }
    }

    private var samplingStrategySection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Sampling Strategy")
                .font(.headline)
                .padding(.horizontal, Spacing.medium)

            Picker("Sampling Strategy", selection: $selectedStrategy) {
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

            if selectedStrategy == .sampling {
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
                TextField("Value", value: $topKSamplingValue, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                    .onChange(of: topKSamplingValue) { _, newValue in
                        if newValue < 1 {
                            topKSamplingValue = 1
                        } else if newValue > 100 {
                            topKSamplingValue = 100
                        }
                    }

                Toggle("", isOn: $useRandomSeed)
                    .labelsHidden()
            }

            Text("The Top-K value determines how many of the most likely tokens to consider. " +
                 "Lower values (10-20) produce more focused, deterministic responses. " +
                 "Higher values (50-100) allow more creative variations.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if useRandomSeed {
                HStack {
                    Image(systemName: "dice")
                        .foregroundColor(.secondary)
                    Text("Using random seed for reproducible variations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, Spacing.small)
            }
        }
        .padding(Spacing.medium)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }

    private func loadStrategyFromGreedySampling() {
        selectedStrategy = useGreedySampling ? .greedy : .default
        if !useGreedySampling {
            topKSamplingValue = 50
            useRandomSeed = true
        }
    }

    private func updateGreedySamplingFromStrategy() {
        useGreedySampling = selectedStrategy == .greedy
    }
}

#Preview {
    ChatInstructionsView(
        instructions: .constant("You are a helpful AI assistant. Please be concise and accurate in your responses."),
        useGreedySampling: .constant(false),
        onApply: { }
    )
}

import AppBenchCore
import SwiftUI

struct AppBenchConfigurationView: View {
    @Bindable var viewModel: AppBenchViewModel

    var body: some View {
        GroupBox("Experiment") {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Suite", selection: $viewModel.selectedSuite) {
                    ForEach(AppBenchSuite.allCases) { suite in
                        Text(suite.displayName).tag(suite)
                    }
                }

                Picker("Model", selection: $viewModel.selectedModel) {
                    ForEach(AppBenchModel.allCases) { model in
                        Text(model.displayName).tag(model)
                    }
                }

                Picker("Session", selection: $viewModel.selectedSessionMode) {
                    ForEach(AppBenchSessionMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }

                if viewModel.selectedModel == .privateCloudCompute {
                    Picker("Reasoning", selection: $viewModel.selectedReasoningLevel) {
                        ForEach(AppBenchReasoningLevel.allCases) { level in
                            Text(level.displayName).tag(level)
                        }
                    }

                    Picker("Fallback", selection: $viewModel.selectedFallbackMode) {
                        ForEach(AppBenchFallbackMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                }

                Picker("Connectivity", selection: $viewModel.selectedConnectivity) {
                    ForEach(AppBenchConnectivity.allCases) { connectivity in
                        Text(connectivity.displayName).tag(connectivity)
                    }
                }

                Stepper(
                    "Warmups: \(viewModel.warmupCount)", value: $viewModel.warmupCount, in: 0...10)
                Stepper(
                    "Measured runs: \(viewModel.repetitions)", value: $viewModel.repetitions,
                    in: 1...50)

                Toggle("Use all 25 samples per workload", isOn: $viewModel.useAllSamples)

                if !viewModel.useAllSamples {
                    Stepper(
                        "Samples per workload: \(viewModel.samplesPerScenario)",
                        value: $viewModel.samplesPerScenario,
                        in: 1...25
                    )
                }

                Toggle("Randomize workload order", isOn: $viewModel.randomizeOrder)

                Button(
                    viewModel.isRunning ? "Running AppBench…" : "Run AppBench",
                    systemImage: "play.fill",
                    action: viewModel.run
                )
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isRunning)
                .accessibilityHint("Runs the selected Foundation Models benchmark configuration")

                if viewModel.isRunning {
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityLabel("AppBench is running")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
        }
    }
}

import AppBenchCore
import SwiftUI

struct AppBenchAdvancedConfigurationView: View {
    @Bindable var viewModel: AppBenchViewModel

    var body: some View {
        Picker("Session", selection: $viewModel.selectedSessionMode) {
            ForEach(AppBenchSessionMode.allCases) { mode in
                Text(mode.displayName).tag(mode)
            }
        }

        Picker("Connectivity", selection: $viewModel.selectedConnectivity) {
            ForEach(AppBenchConnectivity.allCases) { connectivity in
                Text(connectivity.displayName).tag(connectivity)
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

        Stepper(
            "Warmups: \(viewModel.warmupCount)",
            value: $viewModel.warmupCount,
            in: 0...10
        )

        Stepper(
            "Measured runs: \(viewModel.repetitions)",
            value: $viewModel.repetitions,
            in: 1...50
        )

        Toggle("All 25 samples", isOn: $viewModel.useAllSamples)

        if !viewModel.useAllSamples {
            Stepper(
                "Samples per workload: \(viewModel.samplesPerScenario)",
                value: $viewModel.samplesPerScenario,
                in: 1...25
            )
        }

        Toggle("Randomize order", isOn: $viewModel.randomizeOrder)
    }
}

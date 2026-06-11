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

                Stepper("Warmups: \(viewModel.warmupCount)", value: $viewModel.warmupCount, in: 0 ... 5)
                Stepper("Repetitions: \(viewModel.repetitions)", value: $viewModel.repetitions, in: 1 ... 20)

                Button(
                    viewModel.isRunning ? "Running AppBench…" : "Run AppBench",
                    systemImage: "play.fill",
                    action: viewModel.run
                )
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isRunning)

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

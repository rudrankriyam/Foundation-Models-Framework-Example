import AppBenchCore
import SwiftUI

struct ContentView: View {
    @State private var viewModel = AppBenchViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            List {
                Section("Benchmark") {
                    AppBenchConfigurationView(viewModel: viewModel)
                }

                Section {
                    AppBenchScenarioListView(scenarios: viewModel.selectedScenarios)
                }

                if let result = viewModel.result {
                    Section {
                        AppBenchResultView(result: result, copyAction: viewModel.copyMarkdown)
                    }
                }
            }
            .navigationTitle("AppBench")
            .navigationBarTitleDisplayMode(.inline)
            .alert("AppBench Failed", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

#Preview {
    ContentView()
}

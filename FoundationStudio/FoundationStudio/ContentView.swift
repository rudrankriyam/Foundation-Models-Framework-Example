import AppBenchCore
import SwiftUI

struct ContentView: View {
    @State private var viewModel = AppBenchViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    AppBenchHeaderView()
                    AppBenchConfigurationView(viewModel: viewModel)
                    AppBenchScenarioListView(scenarios: viewModel.selectedScenarios)

                    if let result = viewModel.result {
                        AppBenchResultView(result: result, copyAction: viewModel.copyMarkdown)
                    }
                }
                .padding()
                .frame(maxWidth: 920)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Foundation Models AppBench")
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

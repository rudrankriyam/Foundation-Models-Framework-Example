import SwiftUI

struct AdapterStudioContent: View {
    let stage: StudioPipelineStage

#if os(macOS)
    @State private var viewModel = AdapterStudioViewModel()
#endif

    var body: some View {
#if os(macOS)
        @Bindable var viewModel = viewModel

        Group {
            switch stage {
            case .settings:
                AdapterStudioSettingsView(viewModel: viewModel)
            case .runs:
                AdapterStudioRunsView(viewModel: viewModel)
            case .evaluation:
                AdapterStudioEvaluationView(viewModel: viewModel)
            case .preview:
                AdapterStudioPreviewView(viewModel: viewModel)
            case .output:
                AdapterStudioOutputView(viewModel: viewModel)
            }
        }
        .alert(
            "Adapter Studio",
            isPresented: $viewModel.isShowingError
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.presentedError)
        }
#else
        ContentUnavailableView(
            "Adapter Comparison Requires macOS",
            systemImage: "macbook",
            description: Text(
                "Use Foundation Lab on a Mac to import .fmadapter packages. "
                    + "Training and export remain available through the fmas CLI."
            )
        )
#endif
    }
}

#Preview {
    AdapterStudioContent(stage: .settings)
        .padding()
}

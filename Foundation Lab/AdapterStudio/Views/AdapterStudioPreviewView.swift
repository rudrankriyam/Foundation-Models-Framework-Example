#if os(macOS)
import SwiftUI

struct AdapterStudioPreviewView: View {
    @Bindable var viewModel: AdapterStudioViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xLarge) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Adapter Workflow")
                    .font(.title3.bold())

                Text(
                    "Train and export with Apple's toolkit, then use this workspace "
                        + "for a quick base-versus-adapter inspection."
                )
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 0) {
                LabeledContent("1. Configure toolkit", value: "fmas init")
                    .padding(Spacing.medium)
                Divider()
                LabeledContent("2. Install dependencies", value: "fmas setup")
                    .padding(Spacing.medium)
                Divider()
                LabeledContent("3. Train", value: "fmas train-adapter --help")
                    .padding(Spacing.medium)
                Divider()
                LabeledContent("4. Export", value: "fmas export --help")
                    .padding(Spacing.medium)
                Divider()
                LabeledContent(
                    "5. Compare",
                    value: viewModel.adapterContext?.metadata.fileName
                        ?? "Import the .fmadapter package"
                )
                .padding(Spacing.medium)
            }
            .background(
                Color.secondaryBackgroundColor,
                in: .rect(cornerRadius: CornerRadius.large)
            )

            Label(
                "Adapters are tied to a specific system-model version. "
                    + "Retrain and reevaluate them when the compatible OS model changes.",
                systemImage: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90"
            )
            .font(.callout)
            .foregroundStyle(.secondary)
        }
    }
}
#endif

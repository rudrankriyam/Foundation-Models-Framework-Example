#if os(macOS)
import SwiftUI

struct AdapterStudioSettingsView: View {
    @Bindable var viewModel: AdapterStudioViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xLarge) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Adapter Package")
                    .font(.title3.bold())

                Text(
                    "Foundation Lab copies imported .fmadapter packages into "
                        + "Application Support so they remain available across launches."
                )
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            HStack(spacing: Spacing.small) {
                Button(
                    "Import Adapter",
                    systemImage: "tray.and.arrow.down",
                    action: viewModel.importAdapter
                )
                .buttonStyle(.borderedProminent)

                Menu("Saved Adapters", systemImage: "archivebox") {
                    if viewModel.availableAdapters.isEmpty {
                        Text("No saved adapters")
                    } else {
                        ForEach(viewModel.availableAdapters, id: \.self) { url in
                            Button(url.lastPathComponent) {
                                viewModel.loadAdapter(at: url)
                            }
                        }
                    }
                }

                Button(
                    "Show in Finder",
                    systemImage: "folder",
                    action: viewModel.showAdaptersDirectory
                )

                Spacer(minLength: 0)
            }

            if let metadata = viewModel.adapterContext?.metadata {
                AdapterStudioMetadataView(metadata: metadata)
            } else {
                ContentUnavailableView(
                    "No Adapter Loaded",
                    systemImage: "shippingbox",
                    description: Text(
                        "Import an adapter or choose one already saved by Foundation Lab."
                    )
                )
                .frame(maxWidth: .infinity, minHeight: 220)
                .background(
                    Color.secondaryBackgroundColor,
                    in: .rect(cornerRadius: CornerRadius.large)
                )
            }
        }
    }
}
#endif

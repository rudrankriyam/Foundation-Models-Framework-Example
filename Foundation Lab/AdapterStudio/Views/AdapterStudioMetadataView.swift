#if os(macOS)
import SwiftUI

struct AdapterStudioMetadataView: View {
    let metadata: AdapterMetadata

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LabeledContent("Name", value: metadata.fileName)
                .padding(Spacing.medium)

            Divider()

            LabeledContent(
                "Size",
                value: ByteCountFormatter.string(
                    fromByteCount: Int64(metadata.fileSize),
                    countStyle: .file
                )
            )
            .padding(Spacing.medium)

            if let modifiedAt = metadata.modifiedAt {
                Divider()

                LabeledContent {
                    Text(modifiedAt, style: .relative)
                } label: {
                    Text("Modified")
                }
                .padding(Spacing.medium)
            }

            if !metadata.creatorDefinedMetadata.isEmpty {
                Divider()

                ForEach(
                    metadata.creatorDefinedMetadata.keys.sorted(),
                    id: \.self
                ) { key in
                    LabeledContent(
                        key,
                        value: metadata.creatorDefinedMetadata[key] ?? ""
                    )
                    .padding(Spacing.medium)
                }
            }
        }
        .background(
            Color.secondaryBackgroundColor,
            in: .rect(cornerRadius: CornerRadius.large)
        )
    }
}
#endif

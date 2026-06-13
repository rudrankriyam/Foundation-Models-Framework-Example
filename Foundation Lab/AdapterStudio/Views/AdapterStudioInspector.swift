import SwiftUI

struct AdapterStudioInspector: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.large) {
            HStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text("2")
                        .font(.headline.monospacedDigit())
                    Text("Models")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()

                VStack(spacing: 2) {
                    Text("Fresh")
                        .font(.headline)
                    Text("Sessions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()

                VStack(spacing: 2) {
                    Text("Local")
                        .font(.headline)
                    Text("Inference")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 52)
            .accessibilityElement(children: .contain)

            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text("Comparison Rules")
                    .font(.headline)

#if os(macOS)
                Label(
                    "Both models receive the same prompt in fresh sessions.",
                    systemImage: "equal.circle.fill"
                )
                Label(
                    "One model failing does not cancel the other response.",
                    systemImage: "arrow.triangle.branch"
                )
                Label(
                    "Concurrent timing is diagnostic, not a benchmark result.",
                    systemImage: "speedometer"
                )
#else
                Label(
                    "Open Foundation Lab on macOS to load custom adapters.",
                    systemImage: "macbook"
                )
#endif
            }
            .font(.callout)
        }
        .padding(Spacing.large)
    }
}

#Preview {
    AdapterStudioInspector()
        .frame(width: 320)
}

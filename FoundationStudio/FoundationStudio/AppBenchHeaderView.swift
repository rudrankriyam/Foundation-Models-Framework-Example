import SwiftUI

struct AppBenchHeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Practical model evaluation", systemImage: "gauge.with.dots.needle.67percent")
                .font(.title.bold())

            Text(
                "Compare real app-shaped tasks across Apple devices, OS releases, " +
                "the on-device model, and Private Cloud Compute."
            )
            .font(.title3)
            .foregroundStyle(.secondary)

            Text("Quality and speed are reported separately. A faster response does not receive a higher quality score.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

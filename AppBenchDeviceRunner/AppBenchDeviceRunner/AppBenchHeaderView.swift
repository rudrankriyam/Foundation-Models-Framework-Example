import SwiftUI

struct AppBenchHeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Physical-device benchmark runner", systemImage: "iphone.gen3")
                .font(.title.bold())

            Text(
                "This signed iOS harness runs the shared AppBench corpus on an iPhone " +
                "or iPad and exports device results."
            )
            .font(.title3)
            .foregroundStyle(.secondary)

            #if targetEnvironment(simulator)
            Label(
                "Simulator mode is for build and interface validation only. Do not publish these results.",
                systemImage: "exclamationmark.triangle.fill"
            )
            .font(.callout.bold())
            .foregroundStyle(.orange)
            #else
            Text("Official Mac measurements come from AppBenchCLI, not this runner.")
                .font(.callout)
                .foregroundStyle(.secondary)
            #endif
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

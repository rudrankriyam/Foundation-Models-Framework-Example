import AppBenchCore
import SwiftUI

struct AppBenchScenarioRow: View {
    let scenario: AppBenchScenario

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(scenario.title)
                    .font(.headline)
                Spacer()
                Text(scenario.category.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(scenario.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Inspired by \(scenario.inspiredBy.joined(separator: ", "))")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Text(
                "\(scenario.samples.count) fixed samples\(scenario.requiresOS27 ? " • OS 27 or later" : "")"
            )
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }
}

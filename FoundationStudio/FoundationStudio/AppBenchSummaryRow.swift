import AppBenchCore
import SwiftUI

struct AppBenchSummaryRow: View {
    let summary: AppBenchScenarioSummary

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
            GridRow {
                Text(summary.title)
                    .font(.headline)
                Text(summary.promptPassRate, format: .percent.precision(.fractionLength(0)))
                    .font(.headline)
                    .foregroundStyle(summary.promptPassRate == 1 ? .green : .orange)
            }

            GridRow {
                Text("Constraint score")
                    .foregroundStyle(.secondary)
                Text(summary.meanConstraintScore, format: .percent.precision(.fractionLength(1)))
            }

            GridRow {
                Text("Median TTFT")
                    .foregroundStyle(.secondary)
                metric(summary.timeToFirstToken.median, suffix: "s", precision: 3)
            }

            GridRow {
                Text("Median output speed")
                    .foregroundStyle(.secondary)
                metric(summary.outputTokensPerSecond.median, suffix: " tok/s", precision: 2)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: 14))
    }

    private func metric(_ value: Double?, suffix: String, precision: Int) -> Text {
        guard let value else { return Text("n/a") }
        let formatted = value.formatted(.number.precision(.fractionLength(precision)))
        return Text("\(formatted)\(suffix)")
    }
}

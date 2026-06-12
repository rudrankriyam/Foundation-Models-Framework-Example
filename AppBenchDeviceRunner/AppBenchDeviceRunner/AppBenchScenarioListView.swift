import AppBenchCore
import SwiftUI

struct AppBenchScenarioListView: View {
    let scenarios: [AppBenchScenario]

    var body: some View {
        DisclosureGroup("Workloads (\(scenarios.count))") {
            ForEach(scenarios) { scenario in
                AppBenchScenarioRow(scenario: scenario)
            }
        }
    }
}

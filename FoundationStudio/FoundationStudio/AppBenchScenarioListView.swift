import AppBenchCore
import SwiftUI

struct AppBenchScenarioListView: View {
    let scenarios: [AppBenchScenario]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scenarios")
                .font(.title2.bold())

            ForEach(scenarios) { scenario in
                AppBenchScenarioRow(scenario: scenario)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

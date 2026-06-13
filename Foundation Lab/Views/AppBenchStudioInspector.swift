//
//  AppBenchStudioInspector.swift
//  Foundation Lab
//
//  Created by Codex on 6/12/26.
//

import SwiftUI

struct AppBenchStudioInspector: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.large) {
            HStack(spacing: 0) {
                metric(value: "5", title: "Suites")
                Divider()
                metric(value: "10", title: "Workloads")
                Divider()
                metric(value: "2", title: "Runners")
            }
            .frame(height: 52)

            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text("Canonical Execution")
                    .font(.headline)

                note(title: "Mac", detail: "Run the CLI for official macOS results.")
                note(title: "iPhone and iPad", detail: "Use the signed runner on physical hardware.")
                note(title: "Simulator", detail: "Never publish its benchmark output.")
            }
        }
        .padding(Spacing.large)
    }

    private func metric(value: String, title: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline.monospacedDigit())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func note(title: String, detail: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout.bold())
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
    }
}

#Preview {
    AppBenchStudioInspector()
        .frame(width: 300)
}

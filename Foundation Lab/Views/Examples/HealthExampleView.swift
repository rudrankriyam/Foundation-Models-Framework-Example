//
//  HealthExampleView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/23/25.
//

import SwiftUI
import SwiftData

struct HealthExampleView: View {
    var body: some View {
        Group {
#if os(iOS)
            HealthDashboardView()
#else
            HealthUnavailableView()
#endif
        }
        .navigationTitle("Health Dashboard")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
    }
}

struct HealthUnavailableView: View {
    var body: some View {
        VStack {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .padding()

            Text("Health Data Unavailable")
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    HealthExampleView()
        .modelContainer(for: [HealthMetric.self, HealthInsight.self, HealthSession.self])
}

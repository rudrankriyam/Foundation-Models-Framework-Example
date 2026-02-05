//
//  HealthExampleView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/23/25.
//

import SwiftUI
import SwiftData
#if os(iOS) && canImport(HealthKit)
import HealthKit
#endif

struct HealthExampleView: View {
    var body: some View {
        Group {
#if os(iOS) && canImport(HealthKit)
            if HKHealthStore.isHealthDataAvailable() {
                HealthDashboardView()
            } else {
                HealthUnavailableView()
            }
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
                .font(.largeTitle)
                .imageScale(.large)
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

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
        NavigationStack {
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
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .padding()

            Text("Health Data Unavailable")
                .font(.title2)
                .fontWeight(.semibold)

            Text("The Health Dashboard requires HealthKit, which is available on iOS devices.\n\nHealthKit provides access to:\n• Step count and activity data\n• Heart rate monitoring\n• Sleep analysis\n• Workout tracking\n• Personalized health insights")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    HealthExampleView()
        .modelContainer(for: [HealthMetric.self, HealthInsight.self, HealthSession.self])
}

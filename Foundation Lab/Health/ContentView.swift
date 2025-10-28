//
//  ContentView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/23/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        NavigationStack {
            HealthDashboardView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [HealthMetric.self, HealthInsight.self, HealthSession.self])
}

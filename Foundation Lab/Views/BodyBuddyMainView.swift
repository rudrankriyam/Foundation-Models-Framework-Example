//
//  BodyBuddyMainView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 7/1/25.
//

import SwiftUI
import SwiftData

struct BodyBuddyMainView: View {
    var body: some View {
        HealthDashboardView()
            .modelContainer(for: [HealthMetric.self, HealthInsight.self, BodyBuddySession.self])
    }
}

#Preview {
    BodyBuddyMainView()
}
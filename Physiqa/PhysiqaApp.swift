//
//  PhysiqaApp.swift
//  Physiqa
//
//  Created by Rudrank Riyam on 6/23/25.
//

import SwiftUI
import SwiftData

@main
struct PhysiqaApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            HealthMetric.self,
            HealthInsight.self,
            PhysiqaSession.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

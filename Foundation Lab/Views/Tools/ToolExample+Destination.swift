//
//  ToolExample+Destination.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 12/20/25.
//

import SwiftUI

extension ToolExample {
    @MainActor
    @ViewBuilder
    var destination: some View {
        switch self {
        case .weather:
            WeatherToolView()
        case .web:
            WebToolView()
        case .contacts:
            ContactsToolView()
        case .calendar:
            CalendarToolView()
        case .reminders:
            RemindersToolView()
        case .location:
            LocationToolView()
        case .health:
            HealthToolView()
        case .music:
            MusicToolView()
        case .webMetadata:
            WebMetadataToolView()
        }
    }
}

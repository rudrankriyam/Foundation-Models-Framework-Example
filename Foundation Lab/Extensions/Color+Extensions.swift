//
//  Color+Extensions.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 7/1/25.
//

import SwiftUI

extension Color {
    /// The main accent color used throughout the app
    static var main: Color {
        Color.indigo
    }

    /// Secondary background color that adapts to the platform
    static var secondaryBackgroundColor: Color {
        #if os(iOS)
        Color(UIColor.secondarySystemBackground)
        #elseif os(macOS)
        Color(NSColor.controlBackgroundColor)
        #else
        Color.gray.opacity(0.1)
        #endif
    }
}

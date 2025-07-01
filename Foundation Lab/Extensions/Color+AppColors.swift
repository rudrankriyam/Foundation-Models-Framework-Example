//
//  Color+AppColors.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 7/1/25.
//

import SwiftUI
// When using as remote dependency:
// import FoundationLabsKit

// MARK: - Foundation Lab App Colors
extension Color {
    /// The main accent color used throughout Foundation Lab
    static var main: Color {
        Color.mint
    }
}

// MARK: - Foundation Lab Color Scheme
struct FoundationLabColors: AppColorScheme {
    static var primary: Color { .mint }
    static var secondary: Color { .cyan }
    static var accent: Color { .teal }
}
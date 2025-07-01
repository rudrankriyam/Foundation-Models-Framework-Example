//
//  View+Extensions.swift
//  FoundationLabsKit
//
//  Created by Rudrank Riyam on 7/1/25.
//

import SwiftUI

// MARK: - Common View Extensions
public extension View {
    /// Conditionally apply a modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Apply a modifier if a value is not nil
    @ViewBuilder
    func ifLet<Value, Content: View>(_ value: Value?, transform: (Self, Value) -> Content) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
    
    /// Apply a gentle shadow for depth
    func softShadow(radius: CGFloat = 8, opacity: Double = 0.1) -> some View {
        self.shadow(
            color: Color.black.opacity(opacity),
            radius: radius,
            x: 0,
            y: 4
        )
    }
    
    /// Apply a glow effect
    func glow(color: Color, radius: CGFloat = 10) -> some View {
        self.shadow(color: color.opacity(0.6), radius: radius)
            .shadow(color: color.opacity(0.3), radius: radius * 2)
    }
}
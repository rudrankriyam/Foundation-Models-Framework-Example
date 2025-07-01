//
//  View+Extensions.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 7/1/25.
//

import SwiftUI

extension View {
    /// Conditionally apply a modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
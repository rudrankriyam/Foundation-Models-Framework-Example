//
//  TopGradientView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 8/17/25.
//

import SwiftUI

public struct TopGradientView: View {
    @Environment(\.colorScheme) var scheme
    
    private let opacity: Double
    private let endPoint: UnitPoint
    
    public init(opacity: Double = 0.64, endPoint: UnitPoint = .center) {
        self.opacity = opacity
        self.endPoint = endPoint
    }

    // Computed properties for dynamic shader parameters
    private var noiseIntensity: Float {
        scheme == .dark ? 0.4 : 0.2
    }

    private var noiseScale: Float {
        scheme == .dark ? 0.5 : 0.5
    }

    private var noiseFrequency: Float {
        scheme == .dark ? 0.5 : 0.5
    }

    public var body: some View {
        LinearGradient(colors: [
            Color.indigo.opacity(opacity), .antiPrimary
        ], startPoint: .top, endPoint: endPoint)
        .colorEffect(ShaderLibrary.parameterizedNoise(
            .float(noiseIntensity),
            .float(noiseScale),
            .float(noiseFrequency)
        ))
        .ignoresSafeArea()
    }
}

extension Color {
    static var antiPrimary: Color {
        #if os(iOS) || os(tvOS) || os(macCatalyst) || os(visionOS)
        return Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor.black
            } else {
                return UIColor.white
            }
        })
        #else
        return .white
        #endif
    }
}

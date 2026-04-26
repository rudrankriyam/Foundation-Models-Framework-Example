//
//  LanguageExample+Destination.swift
//  FoundationLab
//
//  Created by Codex on 4/26/26.
//

import SwiftUI

extension LanguageExample {
    @MainActor
    @ViewBuilder
    var destination: some View {
        switch self {
        case .languageDetection:
            LanguageDetectionView()
        case .multilingualResponses:
            MultilingualResponsesView()
        case .sessionManagement:
            SessionManagementView()
        case .productionExample:
            ProductionLanguageExampleView()
        }
    }
}

//
//  AnalyzeButton.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import SwiftUI

struct AnalyzeButton: View {
    let action: () async -> Void
    @State private var isLoading = false

    var body: some View {
        Button {
            Task {
                isLoading = true
                await action()
                isLoading = false
            }
        } label: {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: "sparkles")
                }
                Text("Analyze Pokemon")
            }
            .font(.headline)
            .foregroundStyle(.white)
        }
        .disabled(isLoading)
        .buttonStyle(.glassProminent)
    }
}

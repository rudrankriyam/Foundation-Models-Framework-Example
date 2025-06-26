//
//  ErrorView.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import SwiftUI

struct ErrorView: View {
    let error: Error
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)
            
            Text("Failed to fetch Pokemon data")
                .font(.headline)
            
            VStack(spacing: 8) {
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                // Show more detail in debug mode
                #if DEBUG
                Text("Debug: \(String(describing: error))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                #endif
            }
            
            Button("Retry") {
                retry()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        #if os(iOS) || os(macOS)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        #endif
    }
}
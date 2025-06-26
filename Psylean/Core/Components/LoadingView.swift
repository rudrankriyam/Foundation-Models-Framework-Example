//
//  LoadingView.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import SwiftUI

struct LoadingView: View {
    let message: String
    @State private var animateDots = false
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(message)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(40)
        #if os(iOS) || os(macOS)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        #endif
    }
}
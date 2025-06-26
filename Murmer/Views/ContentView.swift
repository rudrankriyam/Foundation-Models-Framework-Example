//
//  ContentView.swift
//  Murmer
//
//  Created by Rudrank Riyam on 6/26/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var audioManager = AudioManager()
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(.systemIndigo).opacity(0.1), Color(.systemPurple).opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Audio reactive blob
            AudioReactiveBlobView(audioManager: audioManager)
                .frame(width: 300, height: 300)
        }
        .onAppear {
            audioManager.startAudioSession()
        }
        .onDisappear {
            audioManager.stopAudioSession()
        }
    }
}

#Preview {
    ContentView()
}

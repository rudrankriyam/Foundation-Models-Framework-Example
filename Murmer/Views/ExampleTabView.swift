//
//  ExampleTabView.swift
//  Murmer
//
//  Created by Rudrank Riyam on 6/26/25.
//

import SwiftUI

struct ExampleTabView: View {
    var body: some View {
        TabView {
            SpeechSynthesizerExampleView()
                .tabItem {
                    Image(systemName: "speaker.wave.3.fill")
                    Text("Text-to-Speech")
                }

            SpeechRecognitionExampleView()
                .tabItem {
                    Image(systemName: "waveform.badge.mic")
                    Text("Speech-to-Text")
                }

            InferenceDemoView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("AI Inference")
                }

            ContentView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Full Demo")
                }
        }
    }
}

#Preview {
    ExampleTabView()
}
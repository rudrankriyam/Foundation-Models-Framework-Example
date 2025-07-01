//
//  ContentView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/9/25.
//

import SwiftUI
import FoundationModels

struct ContentView: View {
    @State private var contentViewModel = ContentViewModel()
    @State private var chatViewModel = ChatViewModel()
    @State private var tabSelection: TabSelection = .examples

    var body: some View {
        TabView(selection: $tabSelection) {
            Tab("Examples", systemImage: "sparkles", value: .examples) {
                NavigationStack {
                    ExamplesView(viewModel: $contentViewModel)
                }
            }

            Tab("Chat", systemImage: "bubble.left.and.bubble.right", value: .chat) {
                NavigationStack {
                    ChatView(viewModel: $chatViewModel)
                }
            }
            
            Tab("Body Buddy", systemImage: "heart.text.square", value: .bodyBuddy) {
                NavigationStack {
                    BodyBuddyMainView()
                }
            }
            
            Tab("Psylean", systemImage: "sparkles.rectangle.stack", value: .psylean) {
                NavigationStack {
                    PsyleanMainView()
                }
            }

            Tab("Settings", systemImage: "gear", value: .settings) {
                NavigationStack {
                    SettingsView()
                }
            }
        }
#if os(iOS)
        .ignoresSafeArea(.keyboard)
#endif
    }
}

#Preview {
    ContentView()
}

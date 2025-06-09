//
//  ContentView.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/9/25.
//

import SwiftUI
import FoundationModels

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }

    private func systemPromptExample() async throws {
        let session = LanguageModelSession(instructions: "You are a helpful assistant.")
    }

    private func chatExample() async throws {
        let session = LanguageModelSession()
        let prompt = "Suggest a catchy name for a new coffee shop."
        let response = try await session.respond(to: prompt)
        print(response.content)
    }

    private func structuredDataExample() async throws {
        let session = LanguageModelSession()

        let bookInfo = try await session.respond(
            to: "Suggest a sci-fi book.",
            generating: Book.self
        )
        print(bookInfo.content.title)
    }
}

@Generable
struct Book {
    let title: String
    let author: String
}

#Preview {
    ContentView()
}

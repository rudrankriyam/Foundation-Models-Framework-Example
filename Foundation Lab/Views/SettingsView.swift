//
//  SettingsView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/15/25.
//

import SwiftUI
import LiquidGlasKit

struct SettingsView: View {
    @AppStorage("exaAPIKey") private var exaAPIKey: String = ""
    @State private var tempAPIKey: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @FocusState private var isAPIFieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Exa Web Search")
                    .font(.headline)

                Text("Configure your Exa API key to enable web search functionality.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("API Key")
                    .font(.subheadline)
                    .fontWeight(.medium)

                SecureField("Enter your Exa API key", text: $tempAPIKey)
                    .textFieldStyle(.roundedBorder)
                    .focused($isAPIFieldFocused)
                    .onAppear {
                        tempAPIKey = exaAPIKey
                    }
                    .submitLabel(.done)
                    .onSubmit {
                        saveAPIKey()
                    }

                Text("Get your free Exa API key:")
                Link("https://exa.ai/api", destination: URL(string: "https://exa.ai/api")!)
                    .font(.caption)

                Text("The API key is stored on the device and only used for web search requests.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .glassCard()
            .padding([.horizontal, .top])

            HStack {
                Button("Save") {
                    saveAPIKey()
                }
                .controlSize(.large)
                .buttonStyle(.glassProminent)
                .disabled(tempAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if !exaAPIKey.isEmpty {
                    Button("Clear") {
                        clearAPIKey()
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.secondary)
                    .foregroundColor(.red)
                }
            }

            if !exaAPIKey.isEmpty {
                Text("API key configured")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                Link(destination: URL(string: "https://github.com/rudrankriyam/Foundation-Models-Framework-Example/issues")!) {
                    HStack {
                        Text("Bug/Feature Request")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                .foregroundColor(.primary)

                Link(destination: URL(string: "https://x.com/rudrankriyam")!) {
                    HStack {
                        Text("Made by Rudrank Riyam")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                .foregroundColor(.primary)

                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
                        .foregroundColor(.secondary)
                }
                Text("Explore on-device AI with Apple's Foundation Models framework.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .glassCard()
            .padding([.horizontal, .top])
        }
#if os(macOS)
        .padding()
#endif
        .navigationTitle("Settings")
        .alert("Settings", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }

    private func saveAPIKey() {
        let trimmedKey = tempAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedKey.isEmpty else {
            alertMessage = "Please enter a valid API key"
            showingAlert = true
            return
        }

        dismissKeyboard()
        exaAPIKey = trimmedKey
        alertMessage = "API key saved successfully!"
        showingAlert = true
    }

    private func clearAPIKey() {
        dismissKeyboard()
        exaAPIKey = ""
        tempAPIKey = ""
        alertMessage = "API key cleared"
        showingAlert = true
    }

    private func dismissKeyboard() {
        isAPIFieldFocused = false
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .background(TopGradientView())
    }
}

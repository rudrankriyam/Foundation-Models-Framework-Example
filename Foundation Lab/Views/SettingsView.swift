//
//  SettingsView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/15/25.
//

import SwiftUI
import LiquidGlasKit
import OSLog

struct SettingsView: View {
    @State private var tempAPIKey: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var hasLoadedInitialKey = false
    @FocusState private var isAPIFieldFocused: Bool
    @Environment(ExaAPIKeyStore.self) private var apiKeyStore
    private let logger = Logger(subsystem: ExaAPIKeyStore.defaultServiceIdentifier, category: "SettingsView")

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

                if !apiKeyStore.cachedKey.isEmpty {
                    Button("Clear") {
                        clearAPIKey()
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.secondary)
                    .foregroundColor(.red)
                }
            }

            if !apiKeyStore.cachedKey.isEmpty {
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
        .onAppear {
            loadStoredAPIKeyIfNeeded()
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
        do {
            try apiKeyStore.save(trimmedKey)
            tempAPIKey = trimmedKey
            alertMessage = "API key saved successfully!"
        } catch {
            alertMessage = "Could not save the API key. Please try again."
            logger.error("Failed to save Exa API key: \(error.localizedDescription, privacy: .public)")
        }
        showingAlert = true
    }

    private func clearAPIKey() {
        dismissKeyboard()
        do {
            try apiKeyStore.clear()
            tempAPIKey = ""
            alertMessage = "API key cleared"
        } catch {
            alertMessage = "Could not clear the API key. Please try again."
            logger.error("Failed to clear Exa API key: \(error.localizedDescription, privacy: .public)")
        }
        showingAlert = true
    }

    private func dismissKeyboard() {
        isAPIFieldFocused = false
    }

    private func loadStoredAPIKeyIfNeeded() {
        guard !hasLoadedInitialKey else { return }
        hasLoadedInitialKey = true

        do {
            let currentKey = try apiKeyStore.load() ?? ""
            tempAPIKey = currentKey
        } catch {
            alertMessage = "Failed to load the stored API key."
            showingAlert = true
            logger.error("Failed to load Exa API key: \(error.localizedDescription, privacy: .public)")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(ExaAPIKeyStore())
            .background(TopGradientView())
    }
}

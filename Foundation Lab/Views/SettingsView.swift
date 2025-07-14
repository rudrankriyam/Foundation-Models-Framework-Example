//
//  SettingsView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/15/25.
//

import SwiftUI

struct SettingsView: View {
  @AppStorage("exaAPIKey") private var exaAPIKey: String = ""
  @State private var tempAPIKey: String = ""
  @State private var showingAlert = false
  @State private var alertMessage = ""
  
  var body: some View {
    NavigationStack {
      Form {
        Section {
          VStack(alignment: .leading, spacing: 8) {
            Text("Exa Web Search")
              .font(.headline)
            
            Text("Configure your Exa API key to enable web search functionality.")
              .font(.caption)
              .foregroundColor(.secondary)
          }
          .padding(.vertical, 4)
          
          VStack(alignment: .leading, spacing: 12) {
            Text("API Key")
              .font(.subheadline)
              .fontWeight(.medium)
            
            SecureField("Enter your Exa API key", text: $tempAPIKey)
              .textFieldStyle(.roundedBorder)
              .onAppear {
                tempAPIKey = exaAPIKey
              }
            
            HStack {
              Button("Save") {
                saveAPIKey()
              }
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
          }
          
          if !exaAPIKey.isEmpty {
            Text("API key configured")
              .font(.caption)
              .foregroundColor(.secondary)
          }
          
        } header: {
          Text("Web Search Configuration")
        } footer: {
          VStack(alignment: .leading, spacing: 8) {
            Text("Get your free Exa API key:")
            Link("https://exa.ai/api", destination: URL(string: "https://exa.ai/api")!)
              .font(.caption)
            
            Text("The API key is stored on the device and only used for web search requests.")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
        
        Section {
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
        } header: {
          Text("About")
        } footer: {
          Text("Explore on-device AI with Apple's Foundation Models framework.")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
      .formStyle(.grouped)
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
  }
  
  private func saveAPIKey() {
    let trimmedKey = tempAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
    
    guard !trimmedKey.isEmpty else {
      alertMessage = "Please enter a valid API key"
      showingAlert = true
      return
    }
    
    exaAPIKey = trimmedKey
    alertMessage = "API key saved successfully!"
    showingAlert = true
  }
  
  private func clearAPIKey() {
    exaAPIKey = ""
    tempAPIKey = ""
    alertMessage = "API key cleared"
    showingAlert = true
  }
}

#Preview {
  SettingsView()
}

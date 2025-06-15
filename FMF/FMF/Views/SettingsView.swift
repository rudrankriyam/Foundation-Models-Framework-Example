//
//  SettingsView.swift
//  FMF
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
            HStack {
              Image(systemName: "magnifyingglass.circle.fill")
                .foregroundColor(.blue)
              Text("Exa Web Search")
                .font(.headline)
            }
            
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
              .buttonStyle(.borderedProminent)
              .disabled(tempAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
              
              if !exaAPIKey.isEmpty {
                Button("Clear") {
                  clearAPIKey()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
              }
            }
          }
          
          if !exaAPIKey.isEmpty {
            HStack {
              Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
              Text("API key configured")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
          
        } header: {
          Text("Web Search Configuration")
        } footer: {
          VStack(alignment: .leading, spacing: 8) {
            Text("Get your free Exa API key:")
            Link("https://exa.ai/api", destination: URL(string: "https://exa.ai/api")!)
              .font(.caption)
            
            Text("The API key is stored securely on your device and only used for web search requests.")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
        
        Section {
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Image(systemName: "info.circle")
                .foregroundColor(.blue)
              Text("About Exa Search")
                .font(.subheadline)
                .fontWeight(.medium)
            }
            
            Text("Exa provides AI-powered web search with:")
              .font(.caption)
              .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
              Text("• Neural and keyword search")
              Text("• High-quality results")
              Text("• Content extraction and summaries")
              Text("• Research paper and news filtering")
            }
            .font(.caption)
            .foregroundColor(.secondary)
          }
          .padding(.vertical, 4)
        } header: {
          Text("Features")
        }
      }
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
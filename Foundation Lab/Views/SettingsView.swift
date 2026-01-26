//
//  SettingsView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/15/25.
//

import SwiftUI
import LiquidGlasKit

struct SettingsView: View {
    var body: some View {
        ScrollView {
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
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}

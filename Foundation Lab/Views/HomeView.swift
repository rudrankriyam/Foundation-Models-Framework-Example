//
//  HomeView.swift
//  FoundationLab
//
//  Created by Codex on 4/26/26.
//

import SwiftUI

struct HomeView: View {
    @Environment(NavigationCoordinator.self) private var navigationCoordinator
    @State private var showingSettings = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xLarge) {
                modelStatusSection
                continueSection
                examplesSection
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.large)
        }
        .navigationTitle("Foundation Lab")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
            }
        }
        .navigationDestination(for: ExampleType.self) { exampleType in
            exampleType.destination
        }
    }

    private var modelStatusSection: some View {
        HStack(spacing: Spacing.medium) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text("Model Ready")
                    .font(.headline)

                Text("Apple Intelligence availability is checked when the app opens.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding()
#if os(iOS) || os(macOS)
        .glassEffect(.regular, in: .rect(cornerRadius: CornerRadius.large))
#else
        .background(Color.gray.opacity(0.1), in: .rect(cornerRadius: CornerRadius.large))
#endif
    }

    private var continueSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            SectionHeader(title: "Continue", subtitle: "Jump into the main model session.")

            Button {
                navigationCoordinator.openChat()
            } label: {
                HStack(spacing: Spacing.medium) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.title2)
                        .foregroundStyle(.tint)
                        .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: Spacing.xSmall) {
                        Text("Session")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text("Chat, stream, speak, and watch context windowing.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding()
                .contentShape(.rect)
#if os(iOS) || os(macOS)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: CornerRadius.large))
#else
                .background(Color.gray.opacity(0.1), in: .rect(cornerRadius: CornerRadius.large))
#endif
            }
            .buttonStyle(.plain)
        }
    }

    private var examplesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            SectionHeader(title: "Examples", subtitle: "The approachable demos already in the app.")

            LazyVGrid(columns: adaptiveGridColumns, spacing: Spacing.large) {
                ForEach(ExampleType.homeExamples) { exampleType in
                    NavigationLink(value: exampleType) {
                        GenericCardView(
                            icon: exampleType.icon,
                            title: exampleType.title,
                            subtitle: exampleType.subtitle
                        )
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var adaptiveGridColumns: [GridItem] {
#if os(iOS)
        [
            GridItem(.flexible(minimum: 140), spacing: Spacing.large),
            GridItem(.flexible(minimum: 140), spacing: Spacing.large)
        ]
#else
        [GridItem(.adaptive(minimum: 240), spacing: Spacing.large)]
#endif
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text(title)
                .font(.headline)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environment(NavigationCoordinator.shared)
}

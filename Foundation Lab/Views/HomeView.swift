//
//  HomeView.swift
//  FoundationLab
//
//  Created by Codex on 4/26/26.
//

import SwiftUI
import FoundationLabCore

struct HomeView: View {
    @State private var showingSettings = false
    @State private var modelAvailability = CheckModelAvailabilityUseCase().execute()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xLarge) {
                modelStatusSection
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
        .onAppear(perform: refreshModelAvailability)
    }

    private var modelStatusSection: some View {
        HStack(spacing: Spacing.medium) {
            Image(systemName: modelStatusIcon)
                .font(.title2)
                .foregroundStyle(modelStatusTint)

            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(modelStatusTitle)
                    .font(.headline)

                Text(modelStatusMessage)
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

    private var modelStatusIcon: String {
        modelAvailability.isAvailable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
    }

    private var modelStatusTint: Color {
        modelAvailability.isAvailable ? .green : .orange
    }

    private var modelStatusTitle: String {
        modelAvailability.isAvailable ? "Model Ready" : "Model Unavailable"
    }

    private var modelStatusMessage: String {
        guard !modelAvailability.isAvailable else {
            return "Apple Intelligence is ready for local Foundation Models."
        }

        switch modelAvailability.reason {
        case .deviceNotEligible:
            return "This device does not support Apple Intelligence."
        case .appleIntelligenceNotEnabled:
            return "Enable Apple Intelligence in Settings to use local models."
        case .modelNotReady:
            return "Apple Intelligence models are still downloading."
        case .unknown, .none:
            return "Apple Intelligence is currently unavailable."
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

    private func refreshModelAvailability() {
        modelAvailability = CheckModelAvailabilityUseCase().execute()
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

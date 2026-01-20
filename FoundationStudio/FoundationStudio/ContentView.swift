//
//  ContentView.swift
//  FoundationStudio
//
//  Created by Rudrank Riyam on 10/25/25.
//

import BenchmarkCore
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)
                        .padding(.top, 40)

                    VStack(spacing: 12) {
                        Text("Foundation Models Benchmark")
                            .font(.title)
                            .bold()

                        Text("Tests Ready!")
                            .font(.headline)
                            .foregroundStyle(.green)
                    }

                    VStack(spacing: 16) {
                        instructionCard(
                            icon: "device",
                            title: "Select Device",
                            description: "Choose your device or simulator from the device selector"
                        )

                        instructionCard(
                            icon: "play",
                            title: "Run Tests",
                            description: "Press Cmd+U to run all benchmark tests"
                        )

                        instructionCard(
                            icon: "doc.text",
                            title: "View Results",
                            description: "Check the Xcode console for formatted benchmark results"
                        )
                    }

                    VStack(spacing: 8) {
                        Text("Available Tests")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 4) {
                            TestRow(
                                testName: "testProductDesignBenchmark",
                                description: "Single benchmark run with .productDesign prompt"
                            )
                            TestRow(testName: "testMultipleBenchmarkRuns", description: "3 iterations with statistics")
                            TestRow(
                                testName: "testCustomPromptBenchmark",
                                description: "Custom prompt with neural networks"
                            )
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
            }
            .navigationTitle("Benchmark Tests")
        }
    }

    private func instructionCard(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct TestRow: View {
    let testName: String
    let description: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(testName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
                Text(description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark")
                .font(.caption)
                .foregroundStyle(.green)
        }
    }
}

#Preview {
    ContentView()
}

//
//  RAGDocumentPickerView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 12/19/25.
//

import SwiftUI
import LumoKit
import UniformTypeIdentifiers

struct RAGDocumentPickerView: View {
    @Bindable var viewModel: RAGChatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: DocumentPickerTab = .documents
    @State private var showFilePicker = false
    @State private var showAddTextSheet = false

    enum DocumentPickerTab: String, CaseIterable {
        case documents = "Documents"
        case samples = "Samples"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Tab", selection: $selectedTab) {
                    ForEach(DocumentPickerTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                switch selectedTab {
                case .documents:
                    DocumentListView(viewModel: viewModel, showFilePicker: $showFilePicker)
                case .samples:
                    SamplesView(viewModel: viewModel)
                }
            }
            .navigationTitle("RAG Documents")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { showFilePicker = true }) {
                            Label("Import File", systemImage: "doc")
                        }

                        Button(action: { showAddTextSheet = true }) {
                            Label("Add Text", systemImage: "text")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.pdf, .plainText, .html, .rtf, .text],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        Task {
                            await viewModel.indexDocument(from: url)
                        }
                    }
                case .failure(let error):
                    viewModel.errorMessage = "Failed to access file: \(error.localizedDescription)"
                    viewModel.showError = true
                }
            }
            .sheet(isPresented: $showAddTextSheet) {
                AddTextSheet(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Document List View

struct DocumentListView: View {
    @Bindable var viewModel: RAGChatViewModel
    @Binding var showFilePicker: Bool

    var body: some View {
        List {
            Section {
                Button(action: { showFilePicker = true }) {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                            .font(.title2)
                            .foregroundStyle(.blue)
                            .frame(width: 40, height: 40)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading) {
                            Text("Import Document")
                                .font(.headline)
                            Text("PDF, Markdown, Text, HTML")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }

            Section {
                if viewModel.indexedDocumentCount > 0 {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("\(viewModel.indexedDocumentCount) documents indexed")
                    }
                } else {
                    ContentUnavailableView(
                        "No Documents",
                        systemImage: "doc.text",
                        description: Text("Import documents to enable RAG-powered conversations")
                    )
                }
            } header: {
                Text("Status")
            }
        }
        .listStyle(.inset)
    }
}

// MARK: - Samples View

struct SamplesView: View {
    @Bindable var viewModel: RAGChatViewModel

    var body: some View {
        List {
            Section {
                Button(action: {
                    Task {
                        await viewModel.loadSampleDocuments()
                    }
                }) {
                    HStack {
                        Image(systemName: "book.pages")
                            .font(.title2)
                            .foregroundStyle(.purple)
                            .frame(width: 40, height: 40)
                            .background(Color.purple.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading) {
                            Text("Load Sample Documents")
                                .font(.headline)
                            Text("Swift Concurrency, Foundation Models, HealthKit")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if viewModel.isSearching {
                            ProgressView()
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isSearching)
            } header: {
                Text("Sample Data")
            } footer: {
                Text("Load pre-built sample documents to test RAG functionality")
            }

            if viewModel.indexedDocumentCount > 0 {
                Section {
                    Button(role: .destructive, action: {
                        Task {
                            await viewModel.resetDatabase()
                        }
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                            Text("Clear All Documents")
                        }
                    }
                }
            }
        }
        .listStyle(.inset)
    }
}

// MARK: - Add Text Sheet

struct AddTextSheet: View {
    @Bindable var viewModel: RAGChatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var content = ""
    @State private var isIndexing = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Document Info") {
                    TextField("Title", text: $title)
                }

                Section("Content") {
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                }
            }
            .navigationTitle("Add Text")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Add") {
                        addDocument()
                    }
                    .disabled(title.isEmpty || content.isEmpty || isIndexing)
                }
            }
            .overlay {
                if isIndexing {
                    ProgressView("Indexing...")
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func addDocument() {
        isIndexing = true
        Task {
            await viewModel.indexText(content, title: title)
            isIndexing = false
            dismiss()
        }
    }
}

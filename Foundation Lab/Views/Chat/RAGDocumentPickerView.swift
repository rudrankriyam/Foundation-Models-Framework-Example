//
//  RAGDocumentPickerView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 12/19/25.
//

import SwiftUI
import LumoKit

struct RAGDocumentPickerView: View {
    @Bindable var viewModel: RAGChatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: DocumentPickerTab = .documents

    enum DocumentPickerTab: String, CaseIterable {
        case documents = "Documents"
        case configuration = "Configuration"
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
                    DocumentListView(viewModel: viewModel)
                case .configuration:
                    RAGConfigurationView(viewModel: viewModel)
                }
            }
            .navigationTitle("RAG Documents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(action: loadSampleDocuments) {
                        Label("Add Samples", systemImage: "doc.badge.plus")
                    }
                }
            }
        }
    }

    private func loadSampleDocuments() {
        viewModel.loadSampleDocuments()
    }
}

// MARK: - Document List View

struct DocumentListView: View {
    @Bindable var viewModel: RAGChatViewModel
    @State private var showAddDocumentSheet = false

    var body: some View {
        List {
            ContentUnavailableView(
                "No Documents",
                systemImage: "doc.text",
                description: Text("Add documents to enable RAG-powered conversations")
            )
        }
        .listStyle(.insetGrouped)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showAddDocumentSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddDocumentSheet) {
            AddDocumentSheet(viewModel: viewModel)
        }
    }
}

// MARK: - Add Document Sheet

struct AddDocumentSheet: View {
    @Bindable var viewModel: RAGChatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var content = ""
    @State private var sourceType: RAGDocument.SourceType = .text
    @State private var isIndexing = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Document Info") {
                    TextField("Title", text: $title)

                    Picker("Source Type", selection: $sourceType) {
                        ForEach(RAGDocument.SourceType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                }

                Section("Content") {
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                }
            }
            .navigationTitle("Add Document")
            .navigationBarTitleDisplayMode(.inline)
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
                    ProgressView("Indexing document...")
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
        dismiss()
    }
}

// MARK: - RAG Configuration View

struct RAGConfigurationView: View {
    @Bindable var viewModel: RAGChatViewModel

    var body: some View {
        Text("Configuration options will appear here")
            .padding()
    }
}

// MARK: - RAG Document Model (for picker)

struct RAGDocument: Identifiable, Equatable {
    let id: UUID
    let title: String
    let content: String
    let sourceType: SourceType
    let chunkCount: Int
    let createdAt: Date

    enum SourceType: String, CaseIterable {
        case pdf = "PDF"
        case markdown = "Markdown"
        case text = "Text"
        case html = "HTML"

        var icon: String {
            switch self {
            case .pdf: return "doc.fill"
            case .markdown: return "text.markdown"
            case .text: return "doc.text"
            case .html: return "globe"
            }
        }
    }

    init(id: UUID = UUID(), title: String, content: String, sourceType: SourceType, chunkCount: Int? = nil) {
        self.id = id
        self.title = title
        self.content = content
        self.sourceType = sourceType
        self.chunkCount = chunkCount ?? max(1, Int(ceil(Double(content.split(separator: " ").count) / 100.0)))
        self.createdAt = Date()
    }
}

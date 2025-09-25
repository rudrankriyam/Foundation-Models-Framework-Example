//
//  ContentView.swift
//  Murmer
//
//  Created by Rudrank Riyam on 6/26/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MurmerViewModel()
    
    var body: some View {
        ZStack {
            if viewModel.permissionService.allPermissionsGranted {
                MurmerMainView(viewModel: viewModel)
            } else {
                PermissionRequestView(permissionService: viewModel.permissionService)
            }
        }
        .onAppear {
            viewModel.permissionService.checkAllPermissions()
        }
        .onChange(of: viewModel.permissionService.allPermissionsGranted) { _, _ in
            // Force view update when permissions change
        }
    }
}

struct MurmerMainView: View {
    @ObservedObject var viewModel: MurmerViewModel
    @State private var blobScale: CGFloat = 1.0
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Header with list selector
                VStack(alignment: .leading, spacing: 16) {
                    GlassDropdown(
                        selectedValue: $viewModel.selectedList,
                        options: viewModel.availableLists,
                        title: "Reminder List"
                    )
                    .frame(maxWidth: 300)
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Main content
                VStack(spacing: 40) {
                    // Minimalist audio reactive blob
                    ZStack {
                        // Subtle glow when listening
                        if viewModel.isListening {
                            Circle()
                                .fill(Color.indigo.opacity(0.2))
                                .frame(width: 140, height: 140)
                                .blur(radius: 8)
                        }
                        
                        AudioReactiveBlobView(speechRecognizer: viewModel.speechRecognizer, listeningState: $viewModel.isListening)
                            .frame(width: 120, height: 120)
                            .onTapGesture {
                                toggleListening()
                            }
                    }
                    
                    // Transcription display
                    if !viewModel.recognizedText.isEmpty || viewModel.isListening || !viewModel.partialText.isEmpty {
                        VStack(spacing: 8) {
                            if viewModel.partialText.isEmpty && (viewModel.isListening || viewModel.speechRecognizer.isRecording) {
                                HStack(spacing: 4) {
                                    ForEach(0..<3) { index in
                                        Circle()
                                            .fill(Color.primary.opacity(0.5))
                                            .frame(width: 8, height: 8)
                                            .scaleEffect(viewModel.isListening ? 1.2 : 0.8)
                                            .animation(
                                                .easeInOut(duration: 0.6)
                                                .repeatForever()
                                                .delay(Double(index) * 0.2),
                                                value: viewModel.isListening
                                            )
                                    }
                                }
                                .padding()
                            } else {
                                let displayText = viewModel.partialText.isEmpty ? viewModel.recognizedText : viewModel.partialText
                                Text(displayText)
                                    .font(.title3)
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.center)
                                    .padding()
                                    .frame(maxWidth: 300)
                                    .onChange(of: viewModel.partialText) { _, newValue in
                                        print("🔄 UI PARTIAL TEXT CHANGED: '\(newValue)'")
                                    }
                            }
                        }
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.regularMaterial)
#if os(iOS) || os(macOS)
                                .glassEffect(.regular, in: .rect(cornerRadius: 16))
#endif
                        }
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                    }
                    
                }
                
                Spacer()
            }
            .padding()
            .background(SimpleTopGradientView())
            .navigationTitle("Murmer")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
#if os(iOS)
            .fullScreenCover(isPresented: $showingSettings) {
                SettingsView(speechSynthesizer: viewModel.speechSynthesizer)
            }
#else
            .sheet(isPresented: $showingSettings) {
                SettingsView(speechSynthesizer: viewModel.speechSynthesizer)
            }
#endif
        }
    }
    
    private func toggleListening() {
        if viewModel.isListening {
            viewModel.stopListening()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                blobScale = 1.0
            }
        } else {
            Task {
                await viewModel.startListening()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    blobScale = 1.2
                }
            }
        }
        
        // Haptic feedback
#if os(iOS)
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
#endif
    }
}

// MARK: - Supporting Views

struct SimpleTopGradientView: View {
    @Environment(\.colorScheme) var scheme
    
    var body: some View {
        LinearGradient(colors: [
            Color.indigo.opacity(0.4), .antiPrimary
        ], startPoint: .top, endPoint: .center)
        .ignoresSafeArea()
    }
}

extension Color {
    static var antiPrimary: Color {
#if os(iOS) || os(tvOS) || os(macCatalyst) || os(visionOS)
        return Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor.black
            } else {
                return UIColor.white
            }
        })
#else
        return .white
#endif
    }
}

#Preview {
    ContentView()
}

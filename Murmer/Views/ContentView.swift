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
            if viewModel.permissionManager.allPermissionsGranted {
                MurmerMainView(viewModel: viewModel)
            } else {
                PermissionRequestView(permissionManager: viewModel.permissionManager)
            }
        }
        .onAppear {
            viewModel.permissionManager.checkAllPermissions()
        }
        .onChange(of: viewModel.permissionManager.allPermissionsGranted) { _, _ in
            // Force view update when permissions change
        }
    }
}

struct MurmerMainView: View {
    @ObservedObject var viewModel: MurmerViewModel
    @State private var blobScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 30) {
            // Header with list selector
            VStack(alignment: .leading, spacing: 16) {
                Text("Murmer")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
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
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 140, height: 140)
                            .blur(radius: 8)
                    }

                    AudioReactiveBlobView(audioManager: viewModel.audioManager, listeningState: $viewModel.isListening)
                        .frame(width: 120, height: 120)
                        .onTapGesture {
                            toggleListening()
                        }
                }
                
                // Transcription display
                if !viewModel.recognizedText.isEmpty || viewModel.isListening {
                    VStack(spacing: 8) {
                        if viewModel.isListening && viewModel.speechRecognizer.state.partialText.isEmpty {
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
                            Text(viewModel.speechRecognizer.state.partialText.isEmpty ? viewModel.recognizedText : viewModel.speechRecognizer.state.partialText)
                                .font(.title3)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)
                                .padding()
                                .frame(maxWidth: 300)
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
                
                // Instructions
                if !viewModel.isListening && viewModel.recognizedText.isEmpty {
                    Text("Tap the blob to start")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .successFeedback(
            isShowing: $viewModel.showSuccess,
            message: "Reminder created: \"\(viewModel.lastCreatedReminder)\""
        )
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
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

#Preview {
    ContentView()
}

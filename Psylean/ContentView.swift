//
//  ContentView.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity.combined(with: .scale))
            } else {
                NavigationStack {
                    PokemonAnalysisView()
                }
                .transition(.asymmetric(
                    insertion: .push(from: .trailing).combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
        .animation(.easeInOut(duration: 0.8), value: showSplash)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showSplash = false
            }
        }
    }
}

struct SplashView: View {
    @State private var animateGradient = false
    @State private var animateLogo = false
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [
                    .red,
                    .orange,
                    .yellow,
                    .green,
                    .blue,
                    .purple
                ],
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .opacity(0.8)
            
            VStack(spacing: 30) {
                // Pokemon ball icon
                Image(systemName: "circle.hexagongrid.circle.fill")
                    .font(.system(size: 120))
                    .foregroundStyle(.white)
                    .scaleEffect(animateLogo ? 1 : 0.5)
                    .rotationEffect(.degrees(animateLogo ? 0 : -180))
                    .shadow(radius: 20)
                
                VStack(spacing: 8) {
                    Text("Psylean")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text("Powered by Foundation Models")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .opacity(animateLogo ? 1 : 0)
                .offset(y: animateLogo ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
            
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                animateLogo = true
            }
        }
    }
}

#Preview {
    ContentView()
}
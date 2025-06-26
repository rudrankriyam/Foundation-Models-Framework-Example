//
//  PokemonLoadingView.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import SwiftUI

struct PokemonLoadingView: View {
    let query: String
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated Pokeball
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.red.opacity(0.8), Color.red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .scaleEffect(pulseScale)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 76, height: 76)
                    .offset(y: 40)
                    .mask(
                        Rectangle()
                            .frame(width: 80, height: 40)
                            .offset(y: 20)
                    )
                
                // Center band
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 80, height: 8)
                
                // Center button
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.black, lineWidth: 3)
                    )
                    .overlay(
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 16, height: 16)
                    )
            }
            .rotationEffect(.degrees(rotationAngle))
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
                }
                
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulseScale = 1.1
                }
            }
            
            VStack(spacing: 12) {
                Text("Searching for Pokemon...")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("\"\(query)\"")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

#Preview {
    PokemonLoadingView(query: "cute grass pokemon")
}
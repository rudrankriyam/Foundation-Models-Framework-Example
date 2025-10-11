//
//  SuccessAnimationView.swift
//  Murmer
//
//  Created by Rudrank Riyam on 6/26/25.
//

import SwiftUI

struct SuccessAnimationView: View {
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0
    @State private var checkmarkScale: CGFloat = 0
    @State private var particleScale: CGFloat = 0

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color.green.opacity(0.2))
                .frame(width: 200, height: 200)
                .scaleEffect(particleScale)
                .opacity(1 - particleScale)

            // Success circle
            Circle()
                .fill(Color.green)
                .frame(width: 100, height: 100)
                .scaleEffect(scale)
                .opacity(opacity)
                #if os(iOS) || os(macOS)
                .glassEffect(.regular, in: .rect(cornerRadius: 20))
                #endif

            // Checkmark
            Image(systemName: "checkmark")
                .font(.system(size: 50, weight: .bold))
                .foregroundStyle(.white)
                .scaleEffect(checkmarkScale)
        }
        .onAppear {
            animateSuccess()
        }
    }

    private func animateSuccess() {
        // Circle animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            scale = 1.0
            opacity = 1.0
        }

        // Checkmark animation (delayed)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.2)) {
            checkmarkScale = 1.0
        }

        // Particle animation (delayed)
        withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
            particleScale = 2.0
        }
    }
}

struct SuccessFeedbackModifier: ViewModifier {
    @Binding var isShowing: Bool
    let message: String

    func body(content: Content) -> some View {
        ZStack {
            content

            if isShowing {
                VStack {
                    Spacer()

                    VStack(spacing: 20) {
                        SuccessAnimationView()
                            .frame(height: 200)

                        Text(message)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.regularMaterial)
                            #if os(iOS) || os(macOS)
                            .glassEffect(.regular, in: .rect(cornerRadius: 20))
                            #endif
                    }
                    .padding()
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale(scale: 0.8).combined(with: .opacity)
                    ))

                    Spacer()
                }
            }
        }
    }
}

extension View {
    func successFeedback(isShowing: Binding<Bool>, message: String) -> some View {
        modifier(SuccessFeedbackModifier(isShowing: isShowing, message: message))
    }
}

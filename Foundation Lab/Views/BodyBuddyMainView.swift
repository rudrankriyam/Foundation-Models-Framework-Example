//
//  BodyBuddyMainView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 7/1/25.
//

import SwiftUI
import SwiftData

struct BodyBuddyMainView: View {
    var body: some View {
        // NOTE: To complete the integration:
        // 1. Add Physiqa files to Foundation Lab target in Xcode
        // 2. Import Physiqa module: `import Physiqa`
        // 3. Replace this view with: HealthDashboardView()
        // 4. Ensure HealthKit permissions are configured
        
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.healthPrimary)
                        
                        Text("Physiqa")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Your Personal Health Coach")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Mock Health Score
                    VStack(spacing: 16) {
                        Text("Today's Health Score")
                            .font(.headline)
                        
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 20)
                                .frame(width: 150, height: 150)
                            
                            Circle()
                                .trim(from: 0, to: 0.75)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.healthPrimary, Color.healthSecondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                                )
                                .frame(width: 150, height: 150)
                                .rotationEffect(.degrees(-90))
                            
                            Text("75")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                        }
                    }
                    .padding(.vertical, 20)
                    
                    // Mock Metrics
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        MetricPlaceholder(icon: "figure.walk", title: "Steps", value: "8,432", color: .stepsColor)
                        MetricPlaceholder(icon: "flame.fill", title: "Calories", value: "456", color: .caloriesColor)
                        MetricPlaceholder(icon: "bed.double.fill", title: "Sleep", value: "7.5 hrs", color: .sleepColor)
                        MetricPlaceholder(icon: "heart.fill", title: "Heart Rate", value: "72 bpm", color: .heartColor)
                    }
                    .padding(.horizontal)
                    
                    // Integration Note
                    VStack(spacing: 12) {
                        Label("Integration Required", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundStyle(.orange)
                        
                        Text("To see the full Physiqa dashboard with live health data, the Physiqa files need to be added to the Foundation Lab target in Xcode.")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .padding()
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Physiqa")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .modelContainer(for: []) // Empty for now, will need [HealthMetric.self, HealthInsight.self, PhysiqaSession.self]
    }
}

struct MetricPlaceholder: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    BodyBuddyMainView()
}
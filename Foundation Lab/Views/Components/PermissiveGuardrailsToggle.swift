//
//  PermissiveGuardrailsToggle.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 12/02/2025.
//

import SwiftUI

struct PermissiveGuardrailsToggle: View {
    @Binding var isEnabled: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Permissive Content Transformations")
                    .font(.callout)
                    .foregroundColor(.primary)

                Text("Allow potentially unsafe content for text transformations")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isEnabled)
                .labelsHidden()
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var isEnabled = false

        var body: some View {
            VStack(spacing: 20) {
                PermissiveGuardrailsToggle(isEnabled: $isEnabled)
                    .padding()
            }
        }
    }

    return PreviewWrapper()
}

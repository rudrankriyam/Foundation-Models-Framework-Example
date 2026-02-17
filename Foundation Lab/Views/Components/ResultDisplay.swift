//
//  ResultDisplay.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Result display component
struct ResultDisplay: View {
  let result: String
  let isSuccess: Bool
  var tokenCount: Int?
  @State private var isCopied = false

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.small) {
      HStack {
        Text("RESULT")
          .font(.footnote)
          .fontWeight(.medium)
          .foregroundColor(.secondary)

        if let tokenCount {
          Text("\(tokenCount) tokens")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.quaternary, in: .capsule)
        }

        Spacer()

        Button(action: copyToClipboard) {
          Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
            .font(.callout)
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, 4)
        }
        .accessibilityLabel(isCopied ? "Copied" : "Copy result")
        .buttonStyle(.glass)
      }

      ScrollView {
        Text(LocalizedStringKey(result))
          .font(.body)
          .textSelection(.enabled)
          .padding(Spacing.medium)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color.gray.opacity(0.1))
          .cornerRadius(12)
      }
      .frame(maxHeight: 300)
    }
  }

  private func copyToClipboard() {
    #if os(iOS)
    UIPasteboard.general.string = result
    UIAccessibility.post(notification: .announcement, argument: "Result copied to clipboard")
    #elseif os(macOS)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(result, forType: .string)
    #endif

    isCopied = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      isCopied = false
    }
  }
}

//
//  ClipboardUtility.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 2/5/26.
//

import SwiftUI

/// A shared utility for clipboard operations across the app.
enum ClipboardUtility {
  /// Copies the given text to the system clipboard.
  /// - Parameter text: The text to copy to the clipboard.
  static func copy(_ text: String) {
    #if os(iOS)
      UIPasteboard.general.string = text
    #elseif os(macOS)
      NSPasteboard.general.clearContents()
      NSPasteboard.general.setString(text, forType: .string)
    #endif
  }

  /// Copies text to clipboard and manages the copied state with automatic reset.
  /// - Parameters:
  ///   - text: The text to copy to the clipboard.
  ///   - isCopied: A binding to the copied state flag that will be set to true and reset after the delay.
  ///   - resetDelay: The delay in seconds before resetting isCopied to false. Defaults to 2 seconds.
  static func copyWithFeedback(_ text: String, isCopied: Binding<Bool>, resetDelay: TimeInterval = 2) {
    copy(text)

    isCopied.wrappedValue = true
    DispatchQueue.main.asyncAfter(deadline: .now() + resetDelay) {
      isCopied.wrappedValue = false
    }
  }
}

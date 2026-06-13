//
//  AdapterProviderError.swift
//  Adapter Studio
//
//  Created by Rudrank Riyam on 10/22/25.
//

import Foundation

/// Errors thrown or emitted by ``AdapterProvider`` when managing adapter files.
enum AdapterProviderError: LocalizedError {

    /// The user dismissed the file selection panel without choosing an adapter.
    ///
    /// This case allows the provider to communicate cancellation to the UI without conflating it with failures that
    /// should be surfaced as actionable alerts.
    case userCancelled

    /// The provider failed to create or access the managed adapters directory.
    ///
    /// The associated message contains the underlying file-system error for diagnostic purposes.
    case directoryCreationFailed(String)

    /// The adapters directory exists but is not writable.
    ///
    /// The associated message contains details about the permission issue.
    case directoryNotWritable(String)

    /// The selected file did not have the expected `.fmadapter` file extension.
    ///
    /// The associated `URL` identifies the mistaken file so the UI can reference it in an alert.
    case invalidFileExtension(URL)

    /// The provider could not copy the selected adapter into the managed directory.
    ///
    /// The message contains the file manager error that triggered the failure.
    case copyFailed(String)

    /// Loading the adapter into memory failed.
    ///
    /// The message is built from the localized description of `SystemLanguageModel.Adapter.AssetError`
    /// or any other underlying error encountered during initialization.
    case loadFailed(String)

    /// The adapter file is corrupted or invalid
    case invalidAdapterFile(String)

    /// The adapter file is too large to process
    case fileTooLarge(UInt64)

    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "Selection cancelled"
        case .directoryCreationFailed(let message):
            return "Failed to prepare adapter directory: \(message)"
        case .directoryNotWritable(let message):
            return "Adapter directory is not writable: \(message)"
        case .invalidFileExtension(let url):
            return "The selected file \"\(url.lastPathComponent)\" is not an .fmadapter package."
        case .copyFailed(let message):
            return "Could not import adapter file: \(message)"
        case .loadFailed(let message):
            return "Unable to load adapter: \(message)"
        case .invalidAdapterFile(let message):
            return "The adapter file is invalid or corrupted: \(message)"
        case .fileTooLarge(let size):
            let sizeString = ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
            return "The adapter file size (\(sizeString)) exceeds the maximum allowed size"
        }
    }
}

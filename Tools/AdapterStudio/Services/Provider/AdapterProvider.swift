//
//  AdapterProvider.swift
//  Adapter Studio
//
//  Created by Rudrank Riyam on 10/22/25.
//

#if canImport(AppKit)
import AppKit
#endif

import Foundation
import FoundationModels
import Observation
import OSLog
import UniformTypeIdentifiers

/// Manages the lifecycle of custom `.fmadapter` packages for the Adapter Studio target.
///
/// The provider wraps discovery, import, and loading steps so views can interact with adapters through
/// observable state instead of duplicating file-management concerns.
@MainActor
@Observable
final class AdapterProvider {

    /// The adapter currently active in the studio, paired with metadata describing the package on disk.
    var context: AdapterContext?

    /// The most recent error encountered while importing or loading an adapter, suitable for UI presentation.
    var lastError: AdapterProviderError?

    @ObservationIgnored private let fileManager: FileManager
    @ObservationIgnored private let logger = Logger(
        subsystem: "com.rudrankriyam.foundation-model-adapterstudio",
        category: "AdapterProvider"
    )
    @ObservationIgnored private let adaptersDirectory: URL

    /// Creates a provider configured to manage adapters inside the Application Support directory.
    ///
    /// - Parameter fileManager: An optional file manager dependency that simplifies testing.
    /// - Throws: ``AdapterProviderError/directoryCreationFailed(_:)`` when the adapters directory cannot be prepared.
    init(fileManager: FileManager = .default) throws {
        self.fileManager = fileManager
        self.adaptersDirectory = try Self.defaultAdaptersDirectory(using: fileManager)
    }

    /// Prompts the user to select an adapter file, then imports and loads the selection.
    ///
    /// Successful imports assign to ``context`` and clear ``lastError``. Any recoverable failure is stored
    /// in ``lastError`` so the UI can present a helpful message.
    func selectAndLoadAdapter() {
        performAdapterOperation {
            guard let fileURL = presentOpenPanel() else {
                throw AdapterProviderError.userCancelled
            }
            return try importAndLoadAdapter(at: fileURL)
        }
    }

    /// Loads an adapter already located inside the managed directory.
    ///
    /// Use this helper when presenting results returned by ``availableAdapterURLs()``.
    func loadExistingAdapter(at url: URL) {
        performAdapterOperation {
            try loadAdapter(from: url)
        }
    }

    /// Returns every adapter package currently available inside the managed directory.
    ///
    /// The results are sorted by filename for stable presentation. Non-`.fmadapter` files are ignored.
    func availableAdapterURLs() -> [URL] {
        guard let enumerator = fileManager.enumerator(at: adaptersDirectory, includingPropertiesForKeys: nil) else {
            return []
        }

        return enumerator.compactMap { element in
            guard
                let url = element as? URL,
                url.pathExtension.lowercased() == Self.adapterExtension
            else {
                return nil
            }

            return url
        }.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
    }
}

extension AdapterProvider {

    /// File extension expected for adapter packages produced by the training toolkit.
    static let adapterExtension = "fmadapter"

    /// Validates that the adapters directory exists and is writable.
    ///
    /// - Parameter directory: The directory URL to validate.
    /// - Throws: ``AdapterProviderError/directoryNotWritable(_:)`` when the directory is not writable.
    static func validateDirectoryAccess(_ directory: URL) throws {
        let fileManager = FileManager.default

        // Check if we can write to the directory
        guard fileManager.isWritableFile(atPath: directory.path) else {
            throw AdapterProviderError.directoryNotWritable("No write permission for directory: \(directory.path)")
        }
    }

    /// Resolves or creates the directory where Adapter Studio stores imported adapters.
    ///
    /// The location is `~/Library/Application Support/AdapterStudio/Adapters`, matching the local workflow
    /// described in the project specification.
    ///
    /// - Parameter fileManager: An optional file manager used to resolve and create the directory.
    /// - Throws: ``AdapterProviderError/directoryCreationFailed(_:)`` when the directory cannot be resolved or created.
    /// - Throws: ``AdapterProviderError/directoryNotWritable(_:)`` when the directory exists but is not writable.
    /// - Returns: An absolute URL to the adapters directory.
    static func defaultAdaptersDirectory(using fileManager: FileManager = .default) throws -> URL {
        guard let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw AdapterProviderError.directoryCreationFailed("Unable to resolve Application Support directory.")
        }

        let adapterStudioDirectory = baseDirectory
            .appendingPathComponent("AdapterStudio", isDirectory: true)
            .appendingPathComponent("Adapters", isDirectory: true)

        if fileManager.fileExists(atPath: adapterStudioDirectory.path) == false {
            do {
                try fileManager.createDirectory(at: adapterStudioDirectory, withIntermediateDirectories: true)
            } catch {
                throw AdapterProviderError.directoryCreationFailed(error.localizedDescription)
            }
        }

        // Validate that the directory is writable
        try validateDirectoryAccess(adapterStudioDirectory)

        return adapterStudioDirectory
    }
}

private extension AdapterProvider {

    /// Handles common error patterns for adapter operations.
    ///
    /// Executes a throwing operation and handles errors consistently by logging and updating state.
    /// - Parameter operation: A throwing closure that produces an AdapterContext.
    func performAdapterOperation(_ operation: () throws -> AdapterContext) {
        do {
            context = try operation()
            lastError = nil
        } catch let error as AdapterProviderError {
            logger.error("Adapter operation error: \(error.localizedDescription)")
            lastError = error
        } catch {
            logger.error("Unexpected adapter operation error: \(error.localizedDescription, privacy: .public)")
            lastError = .loadFailed(error.localizedDescription)
        }
    }

    /// Displays an open panel configured to select a single adapter package.
    ///
    /// - Returns: The URL chosen by the user, or `nil` if the panel is dismissed.
    func presentOpenPanel() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Import Adapter"
        panel.title = "Select a Custom Adapter"

        return panel.runModal() == .OK ? panel.url : nil
    }

    /// Validates that the adapters directory is accessible with proper permissions
    private func validateDirectoryAccess() throws {
        guard fileManager.isWritableFile(atPath: adaptersDirectory.path) else {
            throw AdapterProviderError.directoryCreationFailed("Adapters directory is not writable")
        }
    }

    /// Maximum allowed size for adapter files (1GB)
    private static let maxFileSize: UInt64 = 1024 * 1024 * 1024

    /// Validates an adapter file before loading
    private func validateAdapterFile(at url: URL) throws {
        let fileSize = calculateDirectorySize(url)

        if fileSize > Self.maxFileSize {
            throw AdapterProviderError.fileTooLarge(fileSize)
        }

        // Verify it's a valid package
        guard (try? FileWrapper(url: url, options: .immediate)) != nil else {
            throw AdapterProviderError.invalidAdapterFile("Not a valid package")
        }
    }

    /// Imports an adapter located outside the managed directory and loads it into memory.
    ///
    /// When the incoming adapter already resides in the managed directory the existing file is reused.
    /// Otherwise the package is copied, applying a numeric suffix when a file with the same name exists.
    ///
    /// - Parameter url: Absolute path to the adapter selected by the user.
    /// - Throws: ``AdapterProviderError`` when validation or file operations fail.
    /// - Returns: An ``AdapterContext`` capturing both the adapter and its metadata.
    func importAndLoadAdapter(at url: URL) throws -> AdapterContext {
        try validateDirectoryAccess()
        try validateAdapterFile(at: url)

        guard fileManager.fileExists(atPath: url.path) else {
            throw AdapterProviderError.loadFailed("Adapter file does not exist at path: \(url.path)")
        }

        guard url.pathExtension.lowercased() == Self.adapterExtension else {
            throw AdapterProviderError.invalidFileExtension(url)
        }

        guard fileManager.fileExists(atPath: url.path) else {
            throw AdapterProviderError.loadFailed("Adapter file does not exist at path: \(url.path)")
        }

        let destinationURL: URL
        if url.deletingLastPathComponent().standardizedFileURL == adaptersDirectory.standardizedFileURL {
            destinationURL = url
        } else {
            destinationURL = uniqueDestinationURL(for: url.lastPathComponent)
            do {
                try fileManager.copyItem(at: url, to: destinationURL)
            } catch {
                throw AdapterProviderError.copyFailed(error.localizedDescription)
            }
        }

        return try loadAdapter(from: destinationURL)
    }

    /// Loads an adapter from disk and gathers file metadata for UI surfacing.
    ///
    /// - Parameter url: Location of the adapter package on disk.
    /// - Throws: ``AdapterProviderError/loadFailed(_:)`` when the adapter cannot be instantiated.
    /// - Returns: The resulting ``AdapterContext``.
    func loadAdapter(from url: URL) throws -> AdapterContext {
        do {
            let adapter = try SystemLanguageModel.Adapter(fileURL: url)
            let metadata = try buildMetadata(for: adapter, at: url)
            logger.info("Loaded adapter at \(url.path, privacy: .public)")
            return AdapterContext(adapter: adapter, metadata: metadata)
        } catch let assetError as SystemLanguageModel.Adapter.AssetError {
            throw AdapterProviderError.loadFailed(assetError.localizedDescription)
        } catch {
            throw AdapterProviderError.loadFailed(error.localizedDescription)
        }
    }

    /// Generates a unique destination URL by appending a numeric suffix when a filename collision occurs.
    ///
    /// - Parameter fileName: The desired file name for the adapter copy.
    /// - Returns: A destination URL guaranteed not to overwrite an existing file.
    func uniqueDestinationURL(for fileName: String) -> URL {
        var destination = adaptersDirectory.appendingPathComponent(fileName, isDirectory: false)

        guard fileManager.fileExists(atPath: destination.path) else {
            return destination
        }

        let fileBase = (fileName as NSString).deletingPathExtension
        let fileExtension = (fileName as NSString).pathExtension
        var counter = 2

        while fileManager.fileExists(atPath: destination.path) {
            let candidateName: String
            if fileExtension.isEmpty {
                candidateName = "\(fileBase)-\(counter)"
            } else {
                candidateName = "\(fileBase)-\(counter).\(fileExtension)"
            }
            destination = adaptersDirectory.appendingPathComponent(candidateName, isDirectory: false)
            counter += 1
        }

        return destination
    }

    /// Builds rich metadata for the supplied adapter and backing file URL.
    ///
    /// The metadata includes file-system attributes and any custom metadata saved during export, with values
    /// coerced to `String` to simplify presentation.
    ///
    /// - Parameters:
    ///   - adapter: The instantiated adapter.
    ///   - url: File-system location of the adapter package.
    /// - Throws: An error if file-system attributes cannot be read.
    /// - Returns: An ``AdapterMetadata`` value ready for UI consumption.
    func buildMetadata(for adapter: SystemLanguageModel.Adapter, at url: URL) throws -> AdapterMetadata {
        let resourceKeys: Set<URLResourceKey> = [.fileSizeKey, .creationDateKey, .contentModificationDateKey]
        let resourceValues = try url.resourceValues(forKeys: resourceKeys)

        // For packages (.fmadapter bundles), fileSizeKey returns 0, so calculate total recursively
        let fileSize: UInt64
        if let resourceFileSize = resourceValues.fileSize, resourceFileSize > 0 {
            fileSize = UInt64(resourceFileSize)
        } else {
            // Package/bundle: sum all files recursively
            fileSize = calculateDirectorySize(url)
        }

        let creatorMetadata = adapter.creatorDefinedMetadata.reduce(into: [String: String]()) { partialResult, entry in
            partialResult[entry.key] = String(describing: entry.value)
        }

        return AdapterMetadata(
            location: url,
            fileName: url.lastPathComponent,
            fileSize: fileSize,
            createdAt: resourceValues.creationDate,
            modifiedAt: resourceValues.contentModificationDate,
            creatorDefinedMetadata: creatorMetadata
        )
    }

    /// Recursively calculates total size of all files in a directory.
    /// Used for packages/bundles where `.fileSizeKey` returns 0.
    private func calculateDirectorySize(_ url: URL) -> UInt64 {
        var totalSize: UInt64 = 0

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey]
        ) else {
            logger.error("Failed to create enumerator for directory: \(url.path)")
            return 0
        }

        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
                if resourceValues.isRegularFile == true, let fileSize = resourceValues.fileSize {
                    totalSize += UInt64(fileSize)
                }
            } catch {
                logger.error("Failed to get size for file: \(fileURL.path), error: \(error.localizedDescription)")
                continue
            }
        }

        return totalSize
    }
}

#if os(macOS)
import AppKit
import Foundation
import FoundationModels
import OSLog

@MainActor
final class AdapterProvider {
    static let adapterExtension = "fmadapter"

    private static let maximumFileSize: UInt64 = 1024 * 1024 * 1024
    private static let sizeResourceKeys: Set<URLResourceKey> = [
        .isDirectoryKey,
        .fileSizeKey
    ]

    private let fileManager: FileManager
    private let adaptersDirectory: URL
    private let logger = Logger(
        subsystem: "com.rudrankriyam.foundationlab",
        category: "AdapterProvider"
    )

    init(fileManager: FileManager = .default) throws {
        self.fileManager = fileManager
        adaptersDirectory = try Self.defaultAdaptersDirectory(using: fileManager)
    }

    func selectAndLoadAdapter() throws -> AdapterContext? {
        guard let fileURL = presentOpenPanel() else { return nil }

        let accessedSecurityScope = fileURL.startAccessingSecurityScopedResource()
        defer {
            if accessedSecurityScope {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        return try importAndLoadAdapter(at: fileURL)
    }

    func loadExistingAdapter(at url: URL) throws -> AdapterContext {
        try validateAdapter(at: url)
        return try loadAdapter(from: url)
    }

    func availableAdapterURLs() -> [URL] {
        let resourceKeys: [URLResourceKey] = [.isDirectoryKey]
        let urls = try? fileManager.contentsOfDirectory(
            at: adaptersDirectory,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles]
        )

        return (urls ?? [])
            .filter { $0.pathExtension.lowercased() == Self.adapterExtension }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }

    func revealAdaptersDirectory() {
        NSWorkspace.shared.activateFileViewerSelecting([adaptersDirectory])
    }

    static func defaultAdaptersDirectory(
        using fileManager: FileManager = .default
    ) throws -> URL {
        guard let applicationSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw AdapterProviderError.directoryCreationFailed(
                "Unable to resolve Application Support."
            )
        }

        let directory = applicationSupport
            .appending(path: "FoundationLab", directoryHint: .isDirectory)
            .appending(path: "Adapters", directoryHint: .isDirectory)

        if !fileManager.fileExists(atPath: directory.path) {
            do {
                try fileManager.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true
                )
            } catch {
                throw AdapterProviderError.directoryCreationFailed(
                    error.localizedDescription
                )
            }
        }

        guard fileManager.isWritableFile(atPath: directory.path) else {
            throw AdapterProviderError.directoryNotWritable(directory.path)
        }

        return directory
    }
}

private extension AdapterProvider {
    func presentOpenPanel() -> URL? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = []
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Import"
        panel.title = "Choose an .fmadapter Package"
        panel.message = "Foundation Lab copies the package into Application Support."
        return panel.runModal() == .OK ? panel.url : nil
    }

    func importAndLoadAdapter(at url: URL) throws -> AdapterContext {
        try validateAdapter(at: url)

        let destinationURL: URL
        if url.deletingLastPathComponent().standardizedFileURL
            == adaptersDirectory.standardizedFileURL {
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

    func validateAdapter(at url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else {
            throw AdapterProviderError.loadFailed(
                "No file exists at \(url.path)."
            )
        }

        guard url.pathExtension.lowercased() == Self.adapterExtension else {
            throw AdapterProviderError.invalidFileExtension(url)
        }

        let fileSize = try calculateSize(of: url)
        guard fileSize <= Self.maximumFileSize else {
            throw AdapterProviderError.fileTooLarge(fileSize)
        }
    }

    func loadAdapter(from url: URL) throws -> AdapterContext {
        do {
            let adapter = try SystemLanguageModel.Adapter(fileURL: url)
            let metadata = try buildMetadata(for: adapter, at: url)
            logger.info("Loaded adapter at \(url.path, privacy: .public)")
            return AdapterContext(adapter: adapter, metadata: metadata)
        } catch let assetError as SystemLanguageModel.Adapter.AssetError {
            throw AdapterProviderError.loadFailed(assetError.localizedDescription)
        } catch let providerError as AdapterProviderError {
            throw providerError
        } catch {
            throw AdapterProviderError.loadFailed(error.localizedDescription)
        }
    }

    func uniqueDestinationURL(for fileName: String) -> URL {
        var destination = adaptersDirectory.appending(
            path: fileName,
            directoryHint: .isDirectory
        )
        guard fileManager.fileExists(atPath: destination.path) else {
            return destination
        }

        let baseName = (fileName as NSString).deletingPathExtension
        let pathExtension = (fileName as NSString).pathExtension
        var counter = 2

        while fileManager.fileExists(atPath: destination.path) {
            let candidate = "\(baseName)-\(counter).\(pathExtension)"
            destination = adaptersDirectory.appending(
                path: candidate,
                directoryHint: .isDirectory
            )
            counter += 1
        }

        return destination
    }

    func buildMetadata(
        for adapter: SystemLanguageModel.Adapter,
        at url: URL
    ) throws -> AdapterMetadata {
        let resourceKeys: Set<URLResourceKey> = [
            .creationDateKey,
            .contentModificationDateKey
        ]
        let resourceValues = try url.resourceValues(forKeys: resourceKeys)
        let creatorMetadata = adapter.creatorDefinedMetadata.reduce(
            into: [String: String]()
        ) { result, entry in
            result[entry.key] = String(describing: entry.value)
        }

        return AdapterMetadata(
            location: url,
            fileName: url.lastPathComponent,
            fileSize: try calculateSize(of: url),
            createdAt: resourceValues.creationDate,
            modifiedAt: resourceValues.contentModificationDate,
            creatorDefinedMetadata: creatorMetadata
        )
    }

    func calculateSize(of url: URL) throws -> UInt64 {
        let values = try sizeResourceValues(for: url)
        guard values.isDirectory == true else {
            return try requiredFileSize(from: values, at: url)
        }

        return try directorySize(of: url)
    }

    func directorySize(of url: URL) throws -> UInt64 {
        var enumerationError: Error?
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: Array(Self.sizeResourceKeys),
            errorHandler: { _, error in
                enumerationError = error
                return false
            }
        ) else {
            throw AdapterProviderError.sizeCalculationFailed(
                url,
                "The package could not be enumerated."
            )
        }

        var total: UInt64 = 0
        for case let fileURL as URL in enumerator {
            let values = try sizeResourceValues(for: fileURL)
            guard values.isDirectory != true else { continue }

            let fileSize = try requiredFileSize(from: values, at: fileURL)
            let (newTotal, overflowed) = total.addingReportingOverflow(fileSize)
            guard !overflowed else {
                throw AdapterProviderError.sizeCalculationFailed(
                    url,
                    "The package size exceeds the supported range."
                )
            }
            total = newTotal
        }

        if let enumerationError {
            throw AdapterProviderError.sizeCalculationFailed(
                url,
                enumerationError.localizedDescription
            )
        }

        return total
    }

    func sizeResourceValues(for url: URL) throws -> URLResourceValues {
        do {
            return try url.resourceValues(forKeys: Self.sizeResourceKeys)
        } catch {
            throw AdapterProviderError.sizeCalculationFailed(
                url,
                error.localizedDescription
            )
        }
    }

    func requiredFileSize(
        from values: URLResourceValues,
        at url: URL
    ) throws -> UInt64 {
        guard let fileSize = values.fileSize, fileSize >= 0 else {
            throw AdapterProviderError.sizeCalculationFailed(
                url,
                "The filesystem did not report a valid size."
            )
        }

        return UInt64(fileSize)
    }
}
#endif

//
//  AdapterMetadata.swift
//  Adapter Studio
//
//  Created by Rudrank Riyam on 10/22/25.
//

import Foundation

/// File-system details captured for a loaded adapter package.
struct AdapterMetadata: Sendable {

    /// Absolute file-system location of the `.fmadapter` package.
    let location: URL

    /// Adapter file name as displayed in the UI.
    let fileName: String

    /// File size (in bytes); adapters can be large so surfacing this helps gauge download or storage impact.
    let fileSize: UInt64

    /// Creation timestamp reported by the file system, when available.
    let createdAt: Date?

    /// Last modification timestamp reported by the file system, when available.
    let modifiedAt: Date?

    /// Custom metadata values embedded during adapter export, coerced to `String` for presentation.
    let creatorDefinedMetadata: [String: String]
}

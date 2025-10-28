//
//  VoiceLogging.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 11/14/25.
//

import Foundation
import OSLog

enum VoiceLogging {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "FoundationLab"

    static let state = Logger(subsystem: subsystem, category: "voice.state")
    static let recognition = Logger(subsystem: subsystem, category: "voice.recognition")
    static let synthesis = Logger(subsystem: subsystem, category: "voice.synthesis")
    static let permissions = Logger(subsystem: subsystem, category: "voice.permissions")
    static let health = Logger(subsystem: subsystem, category: "health")

#if DEBUG
    private static let verboseFlag = ProcessInfo.processInfo.environment["VOICE_VERBOSE_LOGS"] == "1"
#endif

    static var isVerboseEnabled: Bool {
#if DEBUG
        verboseFlag
#else
        false
#endif
    }
}

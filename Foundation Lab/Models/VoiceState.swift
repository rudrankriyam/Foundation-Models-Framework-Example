//
//  VoiceState.swift
//  FoundationLab
//
//  Voice mode state machine for multi-turn conversations.
//

import Foundation

enum VoiceState: Equatable {
    case idle
    case preparing
    case listening(partialText: String)
    case processing
    case speaking(response: String)
    case error(message: String)

    var isActive: Bool {
        self != .idle
    }

    var isError: Bool {
        if case .error = self {
            return true
        }
        return false
    }
}

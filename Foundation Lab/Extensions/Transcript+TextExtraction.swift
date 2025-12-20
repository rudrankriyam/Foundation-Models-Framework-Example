//
//  Transcript+TextExtraction.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 12/20/25.
//

import FoundationModels

extension Array where Element == Transcript.Segment {
    func textContentJoined() -> String? {
        let text = compactMap { segment in
            if case .text(let textSegment) = segment {
                return textSegment.content
            }
            return nil
        }.joined(separator: " ")

        return text.isEmpty ? nil : text
    }
}

extension Transcript.Entry {
    func textContent() -> String? {
        switch self {
        case .prompt(let prompt):
            return prompt.segments.textContentJoined()
        case .response(let response):
            return response.segments.textContentJoined()
        case .toolOutput(let toolOutput):
            return toolOutput.segments.textContentJoined()
        default:
            return nil
        }
    }
}

//
//  SpeechRecognitionStateMachineTests.swift
//  MurmerTests
//
//  Created by Codex on 10/21/25.
//

import XCTest
@testable import Murmer

final class SpeechRecognitionStateMachineStateTests: XCTestCase {

    func testIdleStateIsNotActive() {
        XCTAssertFalse(SpeechRecognitionStateMachine.State.idle.isActive)
        XCTAssertTrue(SpeechRecognitionStateMachine.State.idle.canStartListening)
        XCTAssertFalse(SpeechRecognitionStateMachine.State.idle.shouldStopListening)
    }

    func testListeningStateFlags() {
        let state = SpeechRecognitionStateMachine.State.listening
        XCTAssertTrue(state.isActive)
        XCTAssertFalse(state.canStartListening)
        XCTAssertTrue(state.shouldStopListening)
    }

    func testPermissionGrantedStateCanStart() {
        let state = SpeechRecognitionStateMachine.State.permissionGranted
        XCTAssertTrue(state.isActive)
        XCTAssertTrue(state.canStartListening)
        XCTAssertFalse(state.shouldStopListening)
    }

    func testErrorStateResetsFlags() {
        let errorState = SpeechRecognitionStateMachine.State.error(.permissionDenied)
        XCTAssertFalse(errorState.isActive)
        XCTAssertFalse(errorState.canStartListening)
        XCTAssertFalse(errorState.shouldStopListening)
    }
}

//
//  MurmerTests.swift
//  MurmerTests
//
//  Created by Rudrank Riyam on 9/24/25.
//

import XCTest
import Combine
@testable import Murmer

// MARK: - Mock Services

class MockSpeechRecognitionService: SpeechRecognitionService {
    @Published var state: SpeechRecognitionState = .idle
    @Published var hasPermission = true
    @Published var currentAmplitude: Double = 0
    @Published var isRecording = false

    var requestPermissionCalled = false
    var startRecognitionCalled = false
    var stopRecognitionCalled = false

    func requestPermission() async -> Bool {
        requestPermissionCalled = true
        return hasPermission
    }

    func startRecognition() throws {
        startRecognitionCalled = true
        state = .listening()
    }

    func stopRecognition() {
        stopRecognitionCalled = true
        state = .idle
    }
}

class MockSpeechSynthesisService: SpeechSynthesisService {
    @Published var isSpeaking = false
    @Published var error: SpeechSynthesizerError?
    @Published var voicesByLanguage: [String: [AVSpeechSynthesisVoice]] = [:]
    @Published var availableLanguages: [String] = []
    @Published var selectedVoice: AVSpeechSynthesisVoice?

    var synthesizeAndSpeakCalled = false
    var generateAudioFileCalled = false

    func synthesizeAndSpeak(text: String) async throws {
        synthesizeAndSpeakCalled = true
        isSpeaking = true
        // Simulate completion
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        isSpeaking = false
    }

    func generateAudioFile(text: String) async throws -> URL {
        generateAudioFileCalled = true
        return URL(fileURLWithPath: "/tmp/test.caf")
    }
}

class MockInferenceService: InferenceServiceProtocol {
    var processTextCalled = false
    var shouldFail = false

    func processText(_ text: String) async throws -> String {
        processTextCalled = true

        if shouldFail {
            throw NSError(domain: "TestError", code: 1, userInfo: nil)
        }

        return "Mock response for: \(text)"
    }
}

class MockPermissionService: PermissionServiceProtocol {
    @Published var microphonePermissionStatus: MicrophonePermissionStatus = .granted
    @Published var speechPermissionStatus: SFSpeechRecognizerAuthorizationStatus = .authorized
    @Published var remindersPermissionStatus: EKAuthorizationStatus = .authorized
    @Published var allPermissionsGranted = true
    @Published var showPermissionAlert = false
    @Published var permissionAlertMessage = ""

    var checkAllPermissionsCalled = false
    var requestAllPermissionsCalled = false
    var showSettingsAlertCalled = false
    var openSettingsCalled = false

    func checkAllPermissions() {
        checkAllPermissionsCalled = true
    }

    func requestAllPermissions() async -> Bool {
        requestAllPermissionsCalled = true
        return allPermissionsGranted
    }

    func showSettingsAlert() {
        showSettingsAlertCalled = true
    }

    func openSettings() {
        openSettingsCalled = true
    }
}

// MARK: - State Machine Tests

class SpeechRecognitionStateMachineTests: XCTestCase {
    var stateMachine: SpeechRecognitionStateMachine!
    var mockSpeechRecognition: MockSpeechRecognitionService!
    var mockSpeechSynthesis: MockSpeechSynthesisService!
    var mockInference: MockInferenceService!
    var mockPermissions: MockPermissionService!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()

        mockSpeechRecognition = MockSpeechRecognitionService()
        mockSpeechSynthesis = MockSpeechSynthesisService()
        mockInference = MockInferenceService()
        mockPermissions = MockPermissionService()
        cancellables = Set<AnyCancellable>()

        stateMachine = SpeechRecognitionStateMachine(
            speechRecognitionService: mockSpeechRecognition,
            speechSynthesisService: mockSpeechSynthesis,
            inferenceService: mockInference,
            permissionManager: mockPermissions
        )
    }

    override func tearDown() {
        cancellables = nil
        stateMachine = nil
        super.tearDown()
    }

    func testInitialStateIsIdle() {
        XCTAssertEqual(stateMachine.state, .idle)
    }

    func testStartWorkflowWithPermissionsGranted() async {
        // Given
        mockPermissions.allPermissionsGranted = true

        // When
        await stateMachine.startWorkflow()

        // Then
        XCTAssertEqual(stateMachine.state, .listening)
        XCTAssertTrue(mockSpeechRecognition.startRecognitionCalled)
    }

    func testStartWorkflowRequestsPermissionsWhenNotGranted() async {
        // Given
        mockPermissions.allPermissionsGranted = false

        // When
        await stateMachine.startWorkflow()

        // Then
        XCTAssertTrue(mockPermissions.requestAllPermissionsCalled)
    }

    func testStopWorkflowResetsToIdle() {
        // Given
        stateMachine.state = .listening

        // When
        stateMachine.stopWorkflow()

        // Then
        XCTAssertEqual(stateMachine.state, .idle)
        XCTAssertTrue(mockSpeechRecognition.stopRecognitionCalled)
    }

    func testStateTransitionsOnSpeechCompletion() async {
        // Given
        let expectation = XCTestExpectation(description: "State should transition through processing")

        stateMachine.$state
            .dropFirst() // Skip initial idle state
            .sink { state in
                switch state {
                case .processingSpeech(let text):
                    XCTAssertEqual(text, "test speech")
                    expectation.fulfill()
                default:
                    break
                }
            }
            .store(in: &cancellables)

        // When - Simulate speech completion
        mockSpeechRecognition.state = .completed(finalText: "test speech")

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(mockInference.processTextCalled)
    }
}

// MARK: - ViewModel Tests

class MurmerViewModelTests: XCTestCase {
    var viewModel: MurmerViewModel!
    var mockStateMachine: SpeechRecognitionStateMachine!
    var mockPermissions: MockPermissionService!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()

        let mockSpeechRecognition = MockSpeechRecognitionService()
        let mockSpeechSynthesis = MockSpeechSynthesisService()
        let mockInference = MockInferenceService()
        mockPermissions = MockPermissionService()

        mockStateMachine = SpeechRecognitionStateMachine(
            speechRecognitionService: mockSpeechRecognition,
            speechSynthesisService: mockSpeechSynthesis,
            inferenceService: mockInference,
            permissionManager: mockPermissions
        )

        viewModel = MurmerViewModel(
            stateMachine: mockStateMachine,
            permissionManager: mockPermissions
        )

        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        cancellables = nil
        viewModel = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertFalse(viewModel.isListening)
        XCTAssertEqual(viewModel.recognizedText, "")
        XCTAssertFalse(viewModel.showSuccess)
        XCTAssertFalse(viewModel.showError)
    }

    func testStartListeningDelegatesToStateMachine() async {
        // When
        await viewModel.startListening()

        // Then - This would be verified by checking state machine calls
        // In a real test, we'd use a spy/mock to verify the call
    }

    func testStopListeningDelegatesToStateMachine() {
        // When
        viewModel.stopListening()

        // Then - This would be verified by checking state machine calls
    }

    func testStateMachineStateChangesUpdateViewModel() {
        // Given
        let expectation = XCTestExpectation(description: "ViewModel should update when state machine changes")

        viewModel.$isListening
            .dropFirst() // Skip initial value
            .sink { isListening in
                XCTAssertTrue(isListening)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        mockStateMachine.state = .listening

        // Then
        wait(for: [expectation], timeout: 1.0)
    }
}

// MARK: - Dependency Container Tests

class DependencyContainerTests: XCTestCase {
    var container: DependencyContainer!

    override func setUp() {
        super.setUp()
        container = DependencyContainer()
    }

    override func tearDown() {
        container.reset()
        super.tearDown()
    }

    func testSharedInstance() {
        let container1 = DependencyContainer.shared
        let container2 = DependencyContainer.shared
        XCTAssert(container1 === container2, "Shared instance should be singleton")
    }

    func testServiceInstancesAreSingletons() {
        let service1 = container.speechRecognitionService
        let service2 = container.speechRecognitionService
        XCTAssert(service1 === service2, "Services should be singletons within container")
    }

    func testResetClearsInstances() {
        _ = container.speechRecognitionService // Create instance
        XCTAssertNotNil(container.speechRecognitionService as? SpeechRecognizer)

        container.reset()

        // After reset, new instances should be created
        let newService = container.speechRecognitionService
        XCTAssertNotNil(newService)
    }

    func testMockRegistration() {
        let mockService = MockSpeechRecognitionService()
        container.registerMock(mockService, for: SpeechRecognitionService.self)

        let resolvedService = container.speechRecognitionService
        XCTAssert(resolvedService === mockService, "Mock service should be returned")
    }
}

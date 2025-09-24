//
//  DependencyContainer.swift
//  Murmer
//
//  Created by Rudrank Riyam on 9/24/25.
//

import Foundation

/// Dependency injection container for managing service instances
final class DependencyContainer: ServiceFactoryProtocol {

    // MARK: - Singleton

    static let shared = DependencyContainer()

    private init() {}

    // MARK: - Service Instances

    private lazy var _speechRecognitionService: SpeechRecognitionService? = nil
    private lazy var _speechSynthesisService: SpeechSynthesisService? = nil
    private lazy var _inferenceService: InferenceServiceProtocol? = nil
    private lazy var _permissionService: PermissionServiceProtocol? = nil

    // MARK: - Service Factory Methods

    func makeSpeechRecognitionService() -> SpeechRecognitionService {
        if let existing = _speechRecognitionService {
            return existing
        }

        let service = SpeechRecognizer()
        _speechRecognitionService = service
        return service
    }

    func makeSpeechSynthesisService() -> SpeechSynthesisService {
        if let existing = _speechSynthesisService {
            return existing
        }

        let service = SpeechSynthesizer()
        _speechSynthesisService = service
        return service
    }

    func makeInferenceService() -> InferenceServiceProtocol {
        if let existing = _inferenceService {
            return existing
        }

        let service = InferenceService()
        _inferenceService = service
        return service
    }

    func makePermissionService() -> PermissionServiceProtocol {
        if let existing = _permissionService {
            return existing
        }

        let service = PermissionService()
        _permissionService = service
        return service
    }

    // MARK: - Service Resolution

    /// Get the speech recognition service instance
    var speechRecognitionService: SpeechRecognitionService {
        makeSpeechRecognitionService()
    }

    /// Get the speech synthesis service instance
    var speechSynthesisService: SpeechSynthesisService {
        makeSpeechSynthesisService()
    }

    /// Get the AI inference service instance
    var inferenceService: InferenceServiceProtocol {
        makeInferenceService()
    }

    /// Get the permission service instance
    var permissionService: PermissionServiceProtocol {
        makePermissionService()
    }

    // MARK: - Testing Support

    /// Reset all service instances (primarily for testing)
    func reset() {
        _speechRecognitionService = nil
        _speechSynthesisService = nil
        _inferenceService = nil
        _permissionService = nil
    }

    /// Register a mock service for testing (primarily for testing)
    func registerMock<T>(_ service: T, for type: Any.Type) {
        switch type {
        case is SpeechRecognitionService.Type:
            _speechRecognitionService = service as? SpeechRecognitionService
        case is SpeechSynthesisService.Type:
            _speechSynthesisService = service as? SpeechSynthesisService
        case is InferenceServiceProtocol.Type:
            _inferenceService = service as? InferenceServiceProtocol
        case is PermissionServiceProtocol.Type:
            _permissionService = service as? PermissionServiceProtocol
        default:
            break
        }
    }
}

import Foundation
import KeychainAccess
import Observation

/// Wraps Keychain interactions for the Exa API key, providing a single access point.
@Observable
@MainActor
final class ExaAPIKeyStore {
    private let keychain: Keychain
    private let apiKeyIdentifier = "exa_api_key"
    private(set) var cachedKey: String = ""

    init(serviceIdentifier: String = "com.rudrankriyam.FoundationLab", keychain: Keychain? = nil) {
        let baseKeychain = keychain ?? Keychain(service: serviceIdentifier)
        self.keychain = baseKeychain.accessibility(.afterFirstUnlock)
    }

    func load() throws -> String? {
        let value = try keychain.get(apiKeyIdentifier)
        cachedKey = value ?? ""
        return value
    }

    func save(_ value: String) throws {
        try keychain.set(value, key: apiKeyIdentifier)
        cachedKey = value
    }

    func clear() throws {
        try keychain.remove(apiKeyIdentifier)
        cachedKey = ""
    }
}

import Foundation
import KeychainAccess

/// Wraps Keychain interactions for the Exa API key, providing a single access point.
final class ExaAPIKeyStore {
    static let shared = ExaAPIKeyStore()

    private let keychain: Keychain
    private let apiKeyIdentifier = "exa_api_key"

    init(serviceIdentifier: String = "com.rudrankriyam.FoundationLab", keychain: Keychain? = nil) {
        let baseKeychain = keychain ?? Keychain(service: serviceIdentifier)
        self.keychain = baseKeychain.accessibility(.afterFirstUnlock)
    }

    func load() throws -> String? {
        try keychain.get(apiKeyIdentifier)
    }

    func save(_ value: String) throws {
        try keychain.set(value, key: apiKeyIdentifier)
    }

    func clear() throws {
        try keychain.remove(apiKeyIdentifier)
    }
}

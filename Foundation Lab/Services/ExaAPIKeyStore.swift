import Foundation
import KeychainAccess
import Observation

@Observable
@MainActor
final class ExaAPIKeyStore {
    static let defaultServiceIdentifier = "com.rudrankriyam.FoundationLab"
    private static let apiKeyIdentifier = "exa_api_key"

    private let keychain: Keychain
    private(set) var cachedKey: String = ""

    init(serviceIdentifier: String = ExaAPIKeyStore.defaultServiceIdentifier, keychain: Keychain? = nil) {
        let baseKeychain = keychain ?? Keychain(service: serviceIdentifier)
        self.keychain = baseKeychain.accessibility(.afterFirstUnlock)
    }

    func load() throws -> String? {
        let value = try keychain.get(Self.apiKeyIdentifier)
        cachedKey = value ?? ""
        return value
    }

    func save(_ value: String) throws {
        try keychain.set(value, key: Self.apiKeyIdentifier)
        cachedKey = value
    }

    func clear() throws {
        try keychain.remove(Self.apiKeyIdentifier)
        cachedKey = ""
    }
}

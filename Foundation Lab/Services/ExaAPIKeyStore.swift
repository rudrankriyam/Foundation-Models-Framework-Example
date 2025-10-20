import Foundation
import KeychainAccess
import Observation

@Observable
@MainActor
final class ExaAPIKeyStore {
    static let defaultServiceIdentifier = "com.rudrankriyam.FoundationLab"
    private static let apiKeyIdentifier = "exa_api_key"
    static let legacyUserDefaultsKey = "exaAPIKey"

    private let keychain: Keychain
    private(set) var cachedKey: String = ""

    init(serviceIdentifier: String = ExaAPIKeyStore.defaultServiceIdentifier, keychain: Keychain? = nil) {
        let baseKeychain = keychain ?? Keychain(service: serviceIdentifier)
        self.keychain = baseKeychain.accessibility(.afterFirstUnlock)
    }

    func load() async throws -> String? {
        let value = try await Task.detached(priority: .utility) { [keychain] in
            try keychain.get(Self.apiKeyIdentifier)
        }.value
        cachedKey = value ?? ""
        return value
    }

    func save(_ value: String) async throws {
        try await Task.detached(priority: .utility) { [keychain] in
            try keychain.set(value, key: Self.apiKeyIdentifier)
        }.value
        cachedKey = value
    }

    func clear() async throws {
        try await Task.detached(priority: .utility) { [keychain] in
            try keychain.remove(Self.apiKeyIdentifier)
        }.value
        cachedKey = ""
    }
}

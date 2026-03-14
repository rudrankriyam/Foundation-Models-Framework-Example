import Foundation

public protocol ContactsSearching: Sendable {
    func searchContacts(for request: SearchContactsRequest) async throws -> TextGenerationResult
}

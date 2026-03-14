import Foundation
import FoundationModels

@Generable
public struct BookRecommendation: Sendable, Hashable, Codable {
    @Guide(description: "The title of the book")
    public let title: String

    @Guide(description: "The author's name")
    public let author: String

    @Guide(description: "A brief description in 2-3 sentences")
    public let description: String

    @Guide(description: "Genre of the book")
    public let genre: BookGenre

    public init(
        title: String,
        author: String,
        description: String,
        genre: BookGenre
    ) {
        self.title = title
        self.author = author
        self.description = description
        self.genre = genre
    }
}

@Generable
public enum BookGenre: Sendable, Hashable, Codable {
    case fiction
    case nonFiction
    case mystery
    case romance
    case sciFi
    case fantasy
    case biography
    case history
}

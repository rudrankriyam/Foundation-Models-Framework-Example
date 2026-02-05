//
//  BookRecommendationModels.swift
//  FoundationLab
//
//  @Generable models for structured book recommendation generation.
//

import Foundation
import FoundationModels

@Generable
struct BookRecommendation {
    @Guide(description: "The title of the book")
    let title: String

    @Guide(description: "The author's name")
    let author: String

    @Guide(description: "A brief description in 2-3 sentences")
    let description: String

    @Guide(description: "Genre of the book")
    let genre: Genre
}

@Generable
enum Genre {
    case fiction
    case nonFiction
    case mystery
    case romance
    case sciFi
    case fantasy
    case biography
    case history
}

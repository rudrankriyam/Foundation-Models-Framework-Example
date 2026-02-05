//
//  StoryOutlineModels.swift
//  FoundationLab
//
//  @Generable models for structured creative writing generation.
//

import Foundation
import FoundationModels

@Generable
struct StoryOutline {
    @Guide(description: "The title of the story")
    let title: String

    @Guide(description: "Main character name and brief description")
    let protagonist: String

    @Guide(description: "The central conflict or challenge")
    let conflict: String

    @Guide(description: "The setting where the story takes place")
    let setting: String

    @Guide(description: "Story genre")
    let genre: StoryGenre

    @Guide(description: "Major themes explored in the story")
    let themes: [String]
}

@Generable
enum StoryGenre {
    case adventure
    case mystery
    case romance
    case thriller
    case fantasy
    case sciFi
    case horror
    case comedy
}

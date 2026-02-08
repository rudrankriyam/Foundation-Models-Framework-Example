//
//  ProductReviewModels.swift
//  FoundationLab
//
//  @Generable models for structured product review generation.
//

import Foundation
import FoundationModels

@Generable
struct ProductReview {
    @Guide(description: "Product name")
    let productName: String

    @Guide(description: "Rating from 1 to 5")
    let rating: Int

    @Guide(description: "Review text between 50-200 words")
    let reviewText: String

    @Guide(description: "Would recommend this product")
    let recommendation: String

    @Guide(description: "Key pros of the product")
    let pros: [String]

    @Guide(description: "Key cons of the product")
    let cons: [String]
}

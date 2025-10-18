//
//  CardModel.swift
//  ios
//

import Foundation

enum SwipeDirection {
    case up
    case down
    case left
    case right
}

struct Card: Identifiable, Codable {
    let id: String
    let imageURL: String
    let title: String?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case id
        case imageURL = "image_url"
        case title
        case description
    }
}

struct CardResponse: Codable {
    let cards: [Card]
}

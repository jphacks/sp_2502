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
    let isLocalImage: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case imageURL = "image_url"
        case title
        case description
    }

    // APIからのデコード用（isLocalImageはfalse）
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        imageURL = try container.decode(String.self, forKey: .imageURL)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        isLocalImage = false
    }

    // テストモード用のイニシャライザ
    init(id: String, imageURL: String, title: String?, description: String?, isLocalImage: Bool = false) {
        self.id = id
        self.imageURL = imageURL
        self.title = title
        self.description = description
        self.isLocalImage = isLocalImage
    }
}

struct CardResponse: Codable {
    let cards: [Card]
}

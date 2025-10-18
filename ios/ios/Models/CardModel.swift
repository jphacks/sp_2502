import Foundation

enum SwipeDirection {
    case up
    case left
    case right
    case cut
}

struct Card: Identifiable, Codable {
    let id: String
    let imageURL: String
    let title: String?
    let description: String?
    let isLocalImage: Bool
    let emoji: String?
    let taskText: String?

    var isTaskCard: Bool {
        return taskText != nil
    }

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
        emoji = nil
        taskText = nil
    }

    // テストモード用のイニシャライザ
    init(id: String, imageURL: String, title: String?, description: String?, isLocalImage: Bool = false) {
        self.id = id
        self.imageURL = imageURL
        self.title = title
        self.description = description
        self.isLocalImage = isLocalImage
        self.emoji = nil
        self.taskText = nil
    }

    // タスクカード用のイニシャライザ
    init(id: String, imageURL: String, taskText: String, emoji: String, title: String? = nil) {
        self.id = id
        self.imageURL = imageURL
        self.taskText = taskText
        self.emoji = emoji
        self.title = title
        self.description = nil
        self.isLocalImage = true
    }
}

struct CardResponse: Codable {
    let cards: [Card]
}

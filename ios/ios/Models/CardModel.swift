import Foundation

enum SwipeDirection {
    case delete
    case like
    case cut
}

enum TaskStatus: String, Codable {
    case unprocessed
    case active
    case completed
    case waiting
}

struct Card: Identifiable, Codable {
    let id: String
    let imageURL: String
    let title: String?
    let description: String?
    let isLocalImage: Bool
    let emoji: String?
    let taskText: String?

    // Task-related fields (from Drizzle ORM tasks table)
    let userId: String?
    let projectId: String?
    let name: String?
    let date: Date?
    let status: TaskStatus
    let priority: String?
    let parentId: String?
    let createdAt: Date?
    let updatedAt: Date?

    var isTaskCard: Bool {
        return taskText != nil
    }

    var displayName: String {
        return name ?? title ?? "Untitled"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case imageURL = "image_url"
        case title
        case description
        case userId = "user_id"
        case projectId = "project_id"
        case name
        case date
        case status
        case priority
        case parentId = "parent_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
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

        // Task-related fields
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        projectId = try container.decodeIfPresent(String.self, forKey: .projectId)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        date = try container.decodeIfPresent(Date.self, forKey: .date)
        status = try container.decodeIfPresent(TaskStatus.self, forKey: .status) ?? .unprocessed
        priority = try container.decodeIfPresent(String.self, forKey: .priority)
        parentId = try container.decodeIfPresent(String.self, forKey: .parentId)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }

    // テストモード用のイニシャライザ
    init(id: String, imageURL: String, title: String?, description: String?, isLocalImage: Bool = false, userId: String? = nil, projectId: String? = nil, name: String? = nil, date: Date? = nil, status: TaskStatus = .unprocessed, priority: String? = nil, parentId: String? = nil, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.imageURL = imageURL
        self.title = title
        self.description = description
        self.isLocalImage = isLocalImage
        self.emoji = nil
        self.taskText = nil

        // Task-related fields
        self.userId = userId
        self.projectId = projectId
        self.name = name
        self.date = date
        self.status = status
        self.priority = priority
        self.parentId = parentId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // タスクカード用のイニシャライザ
    init(id: String, imageURL: String, taskText: String, emoji: String, title: String? = nil, userId: String? = nil, projectId: String? = nil, name: String? = nil, date: Date? = nil, status: TaskStatus = .unprocessed, priority: String? = nil, parentId: String? = nil) {
        self.id = id
        self.imageURL = imageURL
        self.taskText = taskText
        self.emoji = emoji
        self.title = title
        self.description = nil
        self.isLocalImage = true

        // Task-related fields
        self.userId = userId
        self.projectId = projectId
        self.name = name ?? taskText
        self.date = date
        self.status = status
        self.priority = priority
        self.parentId = parentId
        self.createdAt = Date()
        self.updatedAt = nil
    }
}

struct CardResponse: Codable {
    let cards: [Card]
}

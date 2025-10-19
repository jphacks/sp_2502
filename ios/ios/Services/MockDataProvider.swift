import Foundation

class MockDataProvider {
    static let shared = MockDataProvider()

    private init() {}

    // テスト用のモックカードデータ（タスク構造）
    private let mockCards: [Card] = [
        Card(
            id: "test-1",
            imageURL: "test-card-1",
            title: "テストタスク 1",
            description: "これはテスト用のタスクです",
            isLocalImage: true,
            userId: "test-user",
            projectId: "test-project-1",
            name: "テストタスク 1",
            date: Date(),
            status: .unprocessed,
            priority: "high",
            parentId: nil,
            createdAt: Date(),
            updatedAt: Date()
        ),
        Card(
            id: "test-2",
            imageURL: "test-card-2",
            title: "テストタスク 2",
            description: "未処理タスクのテストデータ",
            isLocalImage: true,
            userId: "test-user",
            projectId: "test-project-1",
            name: "テストタスク 2",
            date: Date().addingTimeInterval(86400), // 明日
            status: .unprocessed,
            priority: "medium",
            parentId: nil,
            createdAt: Date(),
            updatedAt: Date()
        ),
        Card(
            id: "test-3",
            imageURL: "test-card-3",
            title: "テストタスク 3",
            description: "API接続不要でテスト可能",
            isLocalImage: true,
            userId: "test-user",
            projectId: "test-project-2",
            name: "テストタスク 3",
            date: nil,
            status: .unprocessed,
            priority: "low",
            parentId: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    ]

    func fetchCards() async throws -> [Card] {
        // ネットワーク遅延をシミュレート
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        return mockCards
    }

    func sendSwipeAction(cardId: String, action: String) async throws {
        // テストモードではAPIコールをシミュレート
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
        print("🧪 [Test Mode] Swipe action simulated: cardId=\(cardId), action=\(action)")
    }
}

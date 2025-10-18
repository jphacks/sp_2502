//
//  MockDataProvider.swift
//  ios
//

import Foundation

class MockDataProvider {
    static let shared = MockDataProvider()

    private init() {}

    // テスト用のモックカードデータ
    private let mockCards: [Card] = [
        Card(
            id: "test-1",
            imageURL: "test-card-1",
            title: "テストカード 1",
            description: "これはテスト用のカードです",
            isLocalImage: true
        ),
        Card(
            id: "test-2",
            imageURL: "test-card-2",
            title: "テストカード 2",
            description: "ローカル画像を表示しています",
            isLocalImage: true
        ),
        Card(
            id: "test-3",
            imageURL: "test-card-3",
            title: "テストカード 3",
            description: "API接続不要でテスト可能",
            isLocalImage: true
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

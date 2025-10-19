import Foundation
import SwiftUI
import Combine

class CardViewModel: ObservableObject {
    @Published var currentCard: Card?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isGeneratingCard = false
    @Published var generationProgress: String = "" // 生成プロセスの進行状況を表示

    private var cards: [Card] = []
    private let trpcService = tRPCService.shared
    private let mockDataProvider = MockDataProvider.shared
    private let appConfig = AppConfiguration.shared
    private let imageGenerator = ImageGeneratorService.shared
    private let emojiSelector = EmojiSelectorService.shared
    private let keychainHelper = KeychainHelper.shared

    // カードスタック表示用
    func getUpcomingCards(count: Int = 2) -> [Card] {
        guard !cards.isEmpty else { return [] }
        let startIndex = 1
        let endIndex = min(startIndex + count, cards.count)
        return Array(cards[startIndex..<endIndex])
    }

    @MainActor
    func loadCards() async {
        isLoading = true
        errorMessage = nil

        do {
            if appConfig.isTestMode {
                cards = try await mockDataProvider.fetchCards()
                print("🧪 [Test Mode] Loaded \(cards.count) mock cards")
            } else {
                let accessToken = keychainHelper.getAccessToken()
                cards = try await trpcService.fetchCards(accessToken: accessToken)
                print("🌐 [API Mode] Loaded \(cards.count) cards from tRPC")
            }
            currentCard = cards.first
        } catch {
            errorMessage = "Failed to load cards: \(error.localizedDescription)"
        }

        isLoading = false
    }

    @MainActor
    func handleSwipe(direction: SwipeDirection) {
        guard let card = currentCard else { return }

        let action: String
        switch direction {
        case .delete:
            action = "delete"
        case .like:
            action = "like"
        case .cut:
            action = "cut"
        }

        Task { @MainActor in
            do {
                if appConfig.isTestMode {
                    try await mockDataProvider.sendSwipeAction(cardId: card.id, action: action)
                    print("🧪 [Test Mode] Sent action: \(action) for card: \(card.id)")
                } else {
                    let accessToken = keychainHelper.getAccessToken()
                    try await trpcService.sendSwipeAction(cardId: card.id, action: action, accessToken: accessToken)
                    print("🌐 [API Mode] Sent action: \(action) for card: \(card.id)")
                }
            } catch {
                errorMessage = "Failed to send action: \(error.localizedDescription)"
            }
        }

        moveToNextCard()
    }

    @MainActor
    private func moveToNextCard() {
        if let index = cards.firstIndex(where: { $0.id == currentCard?.id }) {
            cards.remove(at: index)
        }

        if cards.isEmpty {
            Task {
                await loadCards()
            }
        } else {
            currentCard = cards.first
        }
    }

    @MainActor
    func handleDelete() {
        handleSwipe(direction: .delete)
    }

    @MainActor
    func handleLike() {
        handleSwipe(direction: .like)
    }

    @MainActor
    func handleCut() {
        handleSwipe(direction: .cut)
    }

    // 音声入力からタスクカードを追加
    @MainActor
    func addTaskCard(taskText: String) async {
        guard !taskText.isEmpty else {
            errorMessage = "タスクが空です"
            return
        }

        isGeneratingCard = true
        errorMessage = nil

        // ステップ1: 絵文字を選択
        generationProgress = "絵文字を選択中..."
        let emoji = emojiSelector.selectEmojiWithPriority(for: taskText)

        // ステップ2: 翻訳と画像を生成
        generationProgress = "画像を生成中..."
        print("🎨 画像生成開始: \(taskText)")
        guard let imagePath = await imageGenerator.generateTaskImage(taskText: taskText, emoji: emoji) else {
            errorMessage = "画像の生成に失敗しました。再度お試しください。"
            print("❌ 画像生成失敗: \(taskText)")
            isGeneratingCard = false
            generationProgress = ""
            return
        }
        print("✅ 画像生成成功: \(imagePath)")

        // ステップ3: タスクカードを作成
        generationProgress = "カードを作成中..."
        let taskCard = Card(
            id: UUID().uuidString,
            imageURL: imagePath,
            taskText: taskText,
            emoji: emoji,
            title: taskText
        )

        // カードスタックの先頭に追加
        cards.insert(taskCard, at: 0)
        currentCard = taskCard

        print("✅ タスクカード作成完了: \(taskText)")

        isGeneratingCard = false
        generationProgress = ""
    }
}

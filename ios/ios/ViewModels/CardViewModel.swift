//
//  CardViewModel.swift
//  ios
//

import Foundation
import SwiftUI
import Combine

class CardViewModel: ObservableObject {
    @Published var currentCard: Card?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isGeneratingCard = false

    private var cards: [Card] = []
    private var swipeHistory: [(card: Card, action: String)] = []
    private let apiService = APIService.shared
    private let mockDataProvider = MockDataProvider.shared
    private let appConfig = AppConfiguration.shared
    private let imageGenerator = ImageGeneratorService.shared
    private let emojiSelector = EmojiSelectorService.shared

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
                cards = try await apiService.fetchCards()
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
        case .up:
            action = "delete"
        case .down:
            action = "skip"
        case .left:
            performUndo()
            return
        case .right:
            action = "like"
        }

        swipeHistory.append((card: card, action: action))

        Task { @MainActor in
            do {
                if appConfig.isTestMode {
                    try await mockDataProvider.sendSwipeAction(cardId: card.id, action: action)
                } else {
                    try await apiService.sendSwipeAction(cardId: card.id, action: action)
                }
            } catch {
                errorMessage = "Failed to send action: \(error.localizedDescription)"
            }
        }

        moveToNextCard()
    }

    @MainActor
    private func performUndo() {
        guard let lastSwipe = swipeHistory.popLast() else { return }

        cards.insert(lastSwipe.card, at: 0)
        currentCard = lastSwipe.card
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
        handleSwipe(direction: .up)
    }

    @MainActor
    func handleLike() {
        handleSwipe(direction: .right)
    }

    @MainActor
    func handleSkip() {
        handleSwipe(direction: .down)
    }

    @MainActor
    func handleUndo() {
        performUndo()
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

        // 絵文字を選択
        let emoji = emojiSelector.selectEmojiWithPriority(for: taskText)

        // 画像を生成
        guard let imagePath = await imageGenerator.generateTaskImage(taskText: taskText, emoji: emoji) else {
            errorMessage = "画像の生成に失敗しました"
            isGeneratingCard = false
            return
        }

        // タスクカードを作成
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
    }
}

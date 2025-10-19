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

        guard let accessToken = keychainHelper.getAccessToken() else {
            errorMessage = "アクセストークンが見つかりません。ログインしてください。"
            isLoading = false
            return
        }

        let fetchedCards = await tRPCService.shared.fetchActiveTasks(token: accessToken)
        print("📥 APIから\(fetchedCards.count)件のタスクを取得しました")

        // 画像生成
        await generateImagesForCards(fetchedCards)

        cards = fetchedCards
        currentCard = cards.first

        isLoading = false
    }

    /// APIから取得したカードに画像を生成する
    @MainActor
    private func generateImagesForCards(_ cardsToUpdate: [Card]) async {
        for i in 0..<cardsToUpdate.count {
            let card = cardsToUpdate[i]
            // 画像URLが空または存在しない場合は生成
            if card.imageURL.isEmpty {
                let taskName = card.displayName
                let emoji = emojiSelector.selectEmojiWithPriority(for: taskName)
                if let imagePath = await imageGenerator.generateTaskImage(taskText: taskName, emoji: emoji) {
                    // imageURLを更新
                    let updatedCard = Card(
                        id: card.id,
                        imageURL: imagePath,
                        taskText: taskName,
                        emoji: emoji,
                        title: card.title,
                        userId: card.userId,
                        projectId: card.projectId,
                        name: card.name,
                        date: card.date,
                        status: card.status,
                        priority: card.priority,
                        parentId: card.parentId
                    )
                    cards[i] = updatedCard
                }
            }
        }
    }

    @MainActor
    func handleSwipe(direction: SwipeDirection) {
        guard let card = currentCard else { return }
        guard let accessToken = keychainHelper.getAccessToken() else {
            errorMessage = "アクセストークンが見つかりません。ログインしてください。"
            return
        }

        Task { @MainActor in
            switch direction {
            case .delete:
                // タスクを削除
                await tRPCService.shared.deleteTask(taskId: card.id, token: accessToken)
                print("🗑️ タスク削除: \(card.id)")
                moveToNextCard()

            case .like:
                // タスクを完了に更新
                await tRPCService.shared.statusUpdateTask(taskId: card.id, status: .completed, token: accessToken)
                print("❤️ Like: \(card.id)")
                moveToNextCard()

            case .cut:
                // AIでタスクを分割
                let result = await tRPCService.shared.splitTaskAI(taskId: card.id, token: accessToken)
                print("✂️ [API Mode] タスク分割成功:")
                print(result)

                // 現在のカードを削除
                moveToNextCard()

                // 分割されたタスクを先頭に挿入
                for re in result.reversed() {
                    let emoji = emojiSelector.selectEmojiWithPriority(for: re.title ?? "")
                    if let imagePath = await imageGenerator.generateTaskImage(taskText: re.title ?? "", emoji: emoji) {
                        let newCard = Card(
                            id: re.id,
                            imageURL: imagePath,
                            taskText: re.title ?? "",
                            emoji: emoji
                        )
                        cards.insert(newCard, at: 0)
                    }
                }

                // 新しい現在のカードを設定
                currentCard = cards.first
            }
        }
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

        // ステップ3: バックエンドにタスクを作成
        generationProgress = "タスクを保存中..."
        guard let accessToken = keychainHelper.getAccessToken() else {
            errorMessage = "アクセストークンが見つかりません。ログインしてください。"
            isGeneratingCard = false
            generationProgress = ""
            return
        }

        guard let taskId = await tRPCService.shared.projectCreateTask(projectName: taskText, TaskName: taskText, token: accessToken) else {
            errorMessage = "タスクの作成に失敗しました。"
            isGeneratingCard = false
            generationProgress = ""
            return
        }

        // ステップ4: 作成したタスクをカードスタックに追加
        let newCard = Card(
            id: taskId,
            imageURL: imagePath,
            taskText: taskText,
            emoji: emoji,
            title: taskText,
            name: taskText
        )
        cards.insert(newCard, at: 0)
        currentCard = cards.first
        print("✅ タスクカード追加成功: \(taskText)")

        isGeneratingCard = false
        generationProgress = ""
    }
}

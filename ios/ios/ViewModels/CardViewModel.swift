import Foundation
import SwiftUI
import Combine

class CardViewModel: ObservableObject {
    @Published var currentCard: Card?
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

        // 次のカードを設定（空の場合はnil）
        currentCard = cards.first
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

        // ステップ1: バックエンドにタスクを作成
        generationProgress = "タスクを保存中..."
        guard let accessToken = keychainHelper.getAccessToken() else {
            errorMessage = "アクセストークンが見つかりません。ログインしてください。"
            isGeneratingCard = false
            generationProgress = ""
            return
        }

        guard var newCard = await tRPCService.shared.projectCreateTask(projectName: taskText, TaskName: taskText, token: accessToken) else {
            errorMessage = "タスクの作成に失敗しました。"
            isGeneratingCard = false
            generationProgress = ""
            return
        }

        // ステップ2: 絵文字を選択
        generationProgress = "絵文字を選択中..."
        let emoji = emojiSelector.selectEmojiWithPriority(for: taskText)

        // ステップ3: 画像を生成
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

        // ステップ4: 画像とemoji情報を追加してカードを更新
        let cardWithImage = Card(
            id: newCard.id,
            imageURL: imagePath,
            taskText: taskText,
            emoji: emoji,
            title: newCard.title,
            userId: newCard.userId,
            projectId: newCard.projectId,
            name: newCard.name,
            date: newCard.date,
            status: newCard.status,
            priority: newCard.priority,
            parentId: newCard.parentId
        )

        // ステップ5: カードスタックに追加
        cards.insert(cardWithImage, at: 0)
        currentCard = cards.first
        print("✅ タスクカード追加成功: \(taskText)")

        isGeneratingCard = false
        generationProgress = ""
    }
}

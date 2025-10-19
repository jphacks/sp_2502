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
            // TODO: task.unprocessedList が実装されたらAPIモードでも使用する
            // 現在はテストモードのみ使用
            cards = try await mockDataProvider.fetchCards()
            print("🧪 [Test Mode] Loaded \(cards.count) mock cards")

            /* バックエンド実装後にコメント解除
            if appConfig.isTestMode {
                cards = try await mockDataProvider.fetchCards()
                print("🧪 [Test Mode] Loaded \(cards.count) mock cards")
            } else {
                let accessToken = keychainHelper.getAccessToken()
                cards = try await trpcService.fetchUnprocessedTasks(order: "desc", accessToken: accessToken)
                print("🌐 [API Mode] Loaded \(cards.count) unprocessed tasks from tRPC")

                // APIから取得したタスクには画像がないので生成する
                await generateImagesForCards()
            }
            */

            currentCard = cards.first
        } catch {
            errorMessage = "Failed to load cards: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// APIから取得したカードに画像を生成する
    @MainActor
    private func generateImagesForCards() async {
        for i in 0..<cards.count {
            let card = cards[i]
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

        Task { @MainActor in
            do {
                switch direction {
                case .delete:
                    // タスクを削除
                    if !appConfig.isTestMode {
                        let accessToken = keychainHelper.getAccessToken()
                        try await trpcService.deleteTask(taskId: card.id, accessToken: accessToken)
                        print("🗑️ [API Mode] タスク削除: \(card.id)")
                    } else {
                        print("🧪 [Test Mode] タスク削除: \(card.id)")
                    }
                    moveToNextCard()

                case .like:
                    // Like アクションは何もしない（次のカードに移動のみ）
                    print("❤️ Like: \(card.id)")
                    moveToNextCard()

                case .cut:
                    // AIでタスクを分割
                    if !appConfig.isTestMode {
                        let accessToken = keychainHelper.getAccessToken()
                        let result = try await trpcService.splitTask(taskId: card.id, accessToken: accessToken)
                        print("✂️ [API Mode] タスク分割成功:")
                        print("  - 1つ目: \(result.firstTaskName) (\(result.firstTaskId))")
                        print("  - 2つ目: \(result.secondTaskName) (\(result.secondTaskId))")

                        // 分割後、カードリストを再読込
                        moveToNextCard()
                        await loadCards()
                    } else {
                        print("🧪 [Test Mode] タスク分割: \(card.id)")
                        moveToNextCard()
                    }
                }
            } catch {
                errorMessage = "アクションの実行に失敗しました: \(error.localizedDescription)"
                print("❌ アクション失敗: \(error)")
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
        do {
            if !appConfig.isTestMode {
                let accessToken = keychainHelper.getAccessToken()
                let createdTask = try await trpcService.createProjectAndTask(
                    projectName: taskText,
                    taskName: taskText,
                    accessToken: accessToken
                )
                print("✅ タスク保存成功: \(createdTask.id)")

                // バックエンドから返されたタスクに画像を追加
                let taskCard = Card(
                    id: createdTask.id,
                    imageURL: imagePath,
                    taskText: taskText,
                    emoji: emoji,
                    title: createdTask.title,
                    userId: createdTask.userId,
                    projectId: createdTask.projectId,
                    name: createdTask.name,
                    date: createdTask.date,
                    status: createdTask.status,
                    priority: createdTask.priority,
                    parentId: createdTask.parentId
                )

                // カードスタックの先頭に追加
                cards.insert(taskCard, at: 0)
                currentCard = taskCard
            } else {
                // テストモード: ローカルのみ
                let taskCard = Card(
                    id: UUID().uuidString,
                    imageURL: imagePath,
                    taskText: taskText,
                    emoji: emoji,
                    title: taskText
                )
                cards.insert(taskCard, at: 0)
                currentCard = taskCard
                print("🧪 [Test Mode] タスクカード作成: \(taskText)")
            }

            print("✅ タスクカード作成完了: \(taskText)")
        } catch {
            errorMessage = "タスクの保存に失敗しました: \(error.localizedDescription)"
            print("❌ タスク保存失敗: \(error)")
        }

        isGeneratingCard = false
        generationProgress = ""
    }
}

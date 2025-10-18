//
//  EmojiSelectorService.swift
//  ios
//

import Foundation

class EmojiSelectorService {
    static let shared = EmojiSelectorService()

    private init() {}

    // キーワードと絵文字のマッピング
    private let emojiMappings: [String: String] = [
        // 学習・勉強関連
        "レポート": "📝",
        "課題": "📚",
        "勉強": "📖",
        "宿題": "✏️",
        "試験": "📝",
        "テスト": "📝",
        "論文": "📄",
        "読書": "📚",
        "学習": "📖",

        // 仕事関連
        "会議": "💼",
        "ミーティング": "💼",
        "プレゼン": "📊",
        "資料": "📑",
        "仕事": "💼",
        "メール": "📧",
        "電話": "📞",
        "打ち合わせ": "🤝",

        // 買い物・生活
        "買い物": "🛒",
        "ショッピング": "🛍️",
        "食材": "🛒",
        "料理": "🍳",
        "掃除": "🧹",
        "洗濯": "👕",
        "片付け": "🧹",

        // 健康・運動
        "運動": "🏃",
        "ジム": "💪",
        "ランニング": "🏃",
        "ヨガ": "🧘",
        "ストレッチ": "🤸",
        "散歩": "🚶",
        "病院": "🏥",
        "薬": "💊",

        // エンタメ・趣味
        "映画": "🎬",
        "音楽": "🎵",
        "ゲーム": "🎮",
        "旅行": "✈️",
        "写真": "📷",
        "絵": "🎨",
        "アート": "🎨",

        // 予定・イベント
        "誕生日": "🎂",
        "パーティー": "🎉",
        "イベント": "🎪",
        "予約": "📅",
        "アポイント": "📅",
        "締切": "⏰",
        "期限": "⏰",

        // 人間関係
        "デート": "💑",
        "友達": "👥",
        "家族": "👨‍👩‍👧‍👦",
        "飲み会": "🍻",

        // その他
        "支払い": "💰",
        "銀行": "🏦",
        "手続き": "📋",
        "申請": "📋",
        "車": "🚗",
        "修理": "🔧",
        "配達": "📦",
        "荷物": "📦"
    ]

    // デフォルトの絵文字（マッチするものがない場合）
    private let defaultEmojis = ["📌", "✅", "⭐", "💡", "🎯"]

    /// タスクテキストから最適な絵文字を選択
    func selectEmoji(for taskText: String) -> String {
        // キーワードマッチング
        for (keyword, emoji) in emojiMappings {
            if taskText.contains(keyword) {
                return emoji
            }
        }

        // マッチするものがない場合はデフォルトからランダムに選択
        return defaultEmojis.randomElement() ?? "📌"
    }

    /// タスクテキストから複数のキーワードに基づいて絵文字を選択（優先度付き）
    func selectEmojiWithPriority(for taskText: String) -> String {
        // 優先度の高いキーワードから順にチェック
        let priorityKeywords = ["締切", "期限", "緊急", "重要", "急ぎ"]

        for keyword in priorityKeywords {
            if taskText.contains(keyword) {
                return emojiMappings[keyword] ?? "⏰"
            }
        }

        // 通常のマッチング
        return selectEmoji(for: taskText)
    }
}

//
//  TranslationService.swift
//  ios
//

import Foundation
import NaturalLanguage

class TranslationService {
    static let shared = TranslationService()

    private init() {}

    /// 日本語テキストを英語に翻訳（簡易的なキーワードマッピング方式）
    /// - Parameter japaneseText: 翻訳する日本語テキスト
    /// - Returns: 翻訳された英語テキスト。失敗時はnil
    func translateToEnglish(japaneseText: String) -> String? {
        guard !japaneseText.isEmpty else {
            return nil
        }

        print("🔄 簡易翻訳開始: \(japaneseText)")

        // キーワードマッピング辞書
        let keywordMappings: [String: String] = [
            // 学習・勉強関連
            "勉強": "study", "学習": "study", "学ぶ": "learn",
            "レポート": "report", "課題": "assignment", "宿題": "homework",
            "テスト": "test", "試験": "exam", "復習": "review",
            "予習": "preparation", "読書": "reading", "本": "book",

            // 仕事・ビジネス関連
            "仕事": "work", "作業": "work", "業務": "business",
            "会議": "meeting", "ミーティング": "meeting", "打ち合わせ": "meeting",
            "プレゼン": "presentation", "発表": "presentation",
            "資料": "document", "書類": "document", "メール": "email",
            "電話": "call", "連絡": "contact",

            // 運動・スポーツ関連
            "運動": "exercise", "トレーニング": "training",
            "ジム": "gym", "ランニング": "running", "走る": "run",
            "筋トレ": "workout", "ヨガ": "yoga", "散歩": "walk",
            "スポーツ": "sports", "サッカー": "soccer", "野球": "baseball",

            // 食事・料理関連
            "料理": "cooking", "調理": "cook", "作る": "make",
            "買い物": "shopping", "食事": "meal", "朝食": "breakfast",
            "昼食": "lunch", "夕食": "dinner", "外食": "eat out",
            "掃除": "cleaning", "洗濯": "laundry",

            // 音楽・エンターテイメント関連
            "音楽": "music", "ピアノ": "piano", "ギター": "guitar",
            "歌": "song", "歌う": "sing", "演奏": "play",
            "映画": "movie", "ドラマ": "drama", "アニメ": "anime",
            "ゲーム": "game", "遊ぶ": "play",

            // 日常・その他
            "起きる": "wake up", "寝る": "sleep", "休む": "rest",
            "出かける": "go out", "帰る": "return", "帰宅": "go home",
            "友達": "friend", "家族": "family", "恋人": "partner",
            "デート": "date", "旅行": "travel", "買う": "buy",
            "送る": "send", "受け取る": "receive", "見る": "watch",
            "聞く": "listen", "話す": "talk", "書く": "write",

            // 時間関連
            "今日": "today", "明日": "tomorrow", "昨日": "yesterday",
            "今週": "this week", "来週": "next week", "先週": "last week",
            "午前": "morning", "午後": "afternoon", "夜": "evening",
            "朝": "morning", "昼": "noon", "夕方": "evening",

            // 場所関連
            "学校": "school", "会社": "office", "家": "home",
            "図書館": "library", "カフェ": "cafe", "公園": "park",
            "駅": "station", "病院": "hospital", "銀行": "bank"
        ]

        var translatedWords: [String] = []
        var foundKeywords = false

        // テキストから各キーワードを検索して置換
        for (japanese, english) in keywordMappings {
            if japaneseText.contains(japanese) {
                translatedWords.append(english)
                foundKeywords = true
            }
        }

        // キーワードが見つかった場合、それらを組み合わせて英語フレーズを作成
        if foundKeywords {
            let translatedText = translatedWords.joined(separator: " ")
            print("✅ 簡易翻訳完了: \(japaneseText) → \(translatedText)")
            return translatedText
        }

        // キーワードが見つからない場合、ジェネリックな英語を返す
        // （日本語をそのまま返すとImagePlayground APIがunsupportedLanguageエラーを返すため）
        print("⚠️ キーワードが見つかりませんでした。ジェネリックな英語を使用: \(japaneseText)")
        return "daily task work activity"
    }

    /// テキストから日本語文字を除去して英語のみにする
    /// - Parameter text: 元のテキスト
    /// - Returns: 日本語文字を除去したテキスト
    func removeJapaneseCharacters(from text: String) -> String {
        // 日本語文字の範囲（ひらがな、カタカナ、漢字）を定義
        let japaneseCharacterSet = CharacterSet(charactersIn: "\u{3040}"..."\u{309F}") // ひらがな
            .union(CharacterSet(charactersIn: "\u{30A0}"..."\u{30FF}")) // カタカナ
            .union(CharacterSet(charactersIn: "\u{4E00}"..."\u{9FAF}")) // 漢字
            .union(CharacterSet(charactersIn: "\u{3400}"..."\u{4DBF}")) // 漢字拡張A

        // 日本語文字を除去
        let filtered = text.unicodeScalars.filter { !japaneseCharacterSet.contains($0) }
        let result = String(String.UnicodeScalarView(filtered)).trimmingCharacters(in: .whitespacesAndNewlines)

        if result.isEmpty {
            return "task"
        }

        return result
    }
}

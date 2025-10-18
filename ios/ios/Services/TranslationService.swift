//
//  TranslationService.swift
//  ios
//

import Foundation
import NaturalLanguage

#if canImport(Translation)
import Translation
#endif

final class TranslationService {
    static let shared = TranslationService()
    private init() {}

    // MARK: - Public API

    /// 旧：辞書ベースの簡易翻訳を「そのまま」使いたいときに呼ぶ
    func basicTranslateToEnglish(japaneseText: String) -> String {
        guard !japaneseText.isEmpty else { return "daily task" }

        print("🔄 簡易翻訳開始: \(japaneseText)")

        let keywordMappings: [String: String] = [
            // 学習・勉強関連
            "勉強": "study", "学習": "study", "学ぶ": "learn", "習う": "learn",
            "レポート": "report", "課題": "assignment", "宿題": "homework",
            "テスト": "test", "試験": "exam", "復習": "review",
            "予習": "preparation", "読書": "reading", "本": "book", "教科書": "textbook",
            "ノート": "note", "メモ": "memo", "研究": "research", "論文": "paper",

            // 仕事・ビジネス関連
            "仕事": "work", "作業": "work", "業務": "business", "タスク": "task",
            "会議": "meeting", "ミーティング": "meeting", "打ち合わせ": "meeting",
            "プレゼン": "presentation", "発表": "presentation",
            "資料": "document", "書類": "document", "メール": "email",
            "電話": "call", "連絡": "contact", "確認": "check", "報告": "report",
            "締切": "deadline", "期限": "deadline", "納期": "due date",

            // 運動・スポーツ関連
            "運動": "exercise", "トレーニング": "training", "体操": "exercise",
            "ジム": "gym", "ランニング": "running", "走る": "run", "ジョギング": "jogging",
            "筋トレ": "workout", "ヨガ": "yoga", "散歩": "walk", "ウォーキング": "walking",
            "スポーツ": "sports", "サッカー": "soccer", "野球": "baseball",
            "バスケ": "basketball", "テニス": "tennis", "水泳": "swimming",

            // 食事・料理関連
            "料理": "cooking", "調理": "cook", "作る": "make", "準備": "prepare",
            "買い物": "shopping", "食事": "meal", "朝食": "breakfast", "朝ごはん": "breakfast",
            "昼食": "lunch", "昼ごはん": "lunch", "夕食": "dinner", "夜ごはん": "dinner",
            "外食": "eat out", "レストラン": "restaurant",
            "掃除": "cleaning", "洗濯": "laundry", "片付け": "organize",

            // 音楽・エンタメ
            "音楽": "music", "ピアノ": "piano", "ギター": "guitar",
            "歌": "song", "歌う": "sing", "演奏": "play", "練習": "practice",
            "映画": "movie", "ドラマ": "drama", "アニメ": "anime",
            "ゲーム": "game", "遊ぶ": "play", "趣味": "hobby",

            // 健康
            "医者": "doctor", "診察": "checkup", "薬": "medicine",
            "健康": "health", "ダイエット": "diet", "美容": "beauty",

            // 日常
            "起きる": "wake up", "寝る": "sleep", "休む": "rest", "休憩": "break",
            "出かける": "go out", "帰る": "return", "帰宅": "go home",
            "友達": "friend", "家族": "family", "恋人": "partner", "親": "parent",
            "デート": "date", "旅行": "travel", "買う": "buy", "購入": "purchase",
            "送る": "send", "受け取る": "receive", "見る": "watch", "観る": "watch",
            "聞く": "listen", "話す": "talk", "書く": "write", "読む": "read",
            "探す": "search", "調べる": "research", "考える": "think",

            // 時間
            "今日": "today", "明日": "tomorrow", "昨日": "yesterday",
            "今週": "this week", "来週": "next week", "先週": "last week",
            "午前": "morning", "午後": "afternoon", "夜": "evening", "深夜": "night",
            "朝": "morning", "昼": "noon", "夕方": "evening",

            // 場所
            "学校": "school", "会社": "office", "家": "home", "自宅": "home",
            "図書館": "library", "カフェ": "cafe", "公園": "park",
            "駅": "station", "病院": "hospital", "銀行": "bank",
            "店": "store", "スーパー": "supermarket", "コンビニ": "convenience store",

            // 動詞
            "する": "do", "やる": "do", "行く": "go", "来る": "come",
            "取る": "take", "持つ": "have", "使う": "use", "開く": "open",
            "閉じる": "close", "始める": "start", "終わる": "finish", "完了": "complete",

            // 形容詞
            "大切": "important", "重要": "important", "急": "urgent", "緊急": "urgent",
            "簡単": "easy", "難しい": "difficult", "楽しい": "fun", "面白い": "interesting"
        ]

        var translatedWords: [String] = []
        var foundKeywords = false

        for (ja, en) in keywordMappings where japaneseText.contains(ja) {
            if !translatedWords.contains(en) {
                translatedWords.append(en)
                foundKeywords = true
            }
        }

        if foundKeywords {
            let cleaned = removeNonEnglishCharacters(from: translatedWords.joined(separator: " "))
            print("✅ 簡易翻訳完了: \(japaneseText) → \(cleaned)")
            return cleaned
        }

        print("⚠️ キーワード未検出。ジェネリック英語を返す: \(japaneseText)")
        return "daily task work activity"
    }

    /// 新：Translation フレームワークでオンデバイス翻訳（iOS 18+）
    /// - Returns: 必ず英字とスペースのみ（API制約に合わせる）
    func translateToEnglish(japaneseText: String) async -> String {
        guard !japaneseText.isEmpty else { return "daily task" }

        #if canImport(Translation)
        if #available(iOS 18.0, *) {
            do {
                let ja = Locale.Language(identifier: "ja")
                let en = Locale.Language(identifier: "en")

                // 端末に日→英の翻訳アセットが入っているか確認
                let availability = LanguageAvailability()
                let status = await availability.status(from: ja, to: en) // .installed / .supported / .unsupported
                // installed 以外は準備不足なので安全にフォールバック（UIでダウンロード促進は別途実装）:
                guard status == .installed else {
                    print("ℹ️ 翻訳モデル未インストール（status=\(status)）。簡易翻訳にフォールバック。")
                    return basicTranslateToEnglish(japaneseText: japaneseText)
                }

                // モデルが入っている端末なら、セッションを直接生成して翻訳
                // init(installedSource:target:) は UI なしの純プログラム実行向け
                let session = try TranslationSession(installedSource: ja, target: en) // iOS 18+
                let response = try await session.translate(japaneseText) // 単一文字列
                let cleaned = removeNonEnglishCharacters(from: response.targetText)
                print("✅ TranslationAPI 翻訳完了: \(japaneseText) → \(cleaned)")
                return cleaned
            } catch {
                print("❌ TranslationAPI 失敗: \(error). 簡易翻訳にフォールバック。")
                return basicTranslateToEnglish(japaneseText: japaneseText)
            }
        }
        #endif

        // iOS 17以下や Translation が使えない環境
        return basicTranslateToEnglish(japaneseText: japaneseText)
    }

    /// 旧API互換：同期メソッド名を残したい場合（呼び出し側がまだ await 化できないときなど）
    @available(*, deprecated, message: "Use await translateToEnglish(japaneseText:) instead.")
    func translateToEnglish(japaneseText: String) -> String {
        return basicTranslateToEnglish(japaneseText: japaneseText)
    }

    // MARK: - Utilities

    /// 英字＋スペースのみを許可して整形
    func removeNonEnglishCharacters(from text: String) -> String {
        let englishOnly = text.filter { char in
            let ascii = char.asciiValue ?? 0
            return (65...90).contains(ascii) || (97...122).contains(ascii) || ascii == 32
        }
        let result = englishOnly
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return result.isEmpty ? "task" : result
    }

    /// 後方互換のため残す（内部的に removeNonEnglishCharacters を利用）
    func removeJapaneseCharacters(from text: String) -> String {
        return removeNonEnglishCharacters(from: text)
    }
}

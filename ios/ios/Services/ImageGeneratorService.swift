import UIKit
import CoreGraphics
import ImagePlayground

class ImageGeneratorService {
    static let shared = ImageGeneratorService()

    // ImageCreatorインスタンスをキャッシュして再利用（iOS 18.4+）
    // 注: stored propertiesに@availableを付けられないため、Any?型で保持してキャスト
    private var cachedImageCreator: Any?

    private init() {}

    func generateTaskImage(taskText: String, emoji: String) async -> String? {
        if #available(iOS 18.4, *) {
            if let imagePath = await generateWithImageCreator(taskText: taskText, emoji: emoji) {
                return imagePath
            }
            print("⚠️ ImageCreator APIが失敗しました。Core Graphicsフォールバックに移行します。")
        } else {
            print("ℹ️ iOS 18.4未満のため、Core Graphicsで画像を生成します。")
        }

        let result = await generateWithCoreGraphics(taskText: taskText, emoji: emoji)
        if result != nil {
            print("✅ Core Graphicsで画像生成成功")
        }
        return result
    }

    @available(iOS 18.4, *)
    private func generateWithImageCreator(taskText: String, emoji: String, retryCount: Int = 0) async -> String? {
        let maxRetries = 1
        let timeoutSeconds: UInt64 = 10 // 10秒のタイムアウト

        do {
            // タイムアウト付きで画像生成を実行
            print("⏱️ ImageCreator API呼び出し開始（タイムアウト: \(timeoutSeconds)秒）")

            return try await withThrowingTaskGroup(of: String?.self) { group in
                // 画像生成タスク
                group.addTask {
                    return try await self.performImageGeneration(taskText: taskText, emoji: emoji)
                }

                // タイムアウトタスク
                group.addTask {
                    try await Task.sleep(nanoseconds: timeoutSeconds * 1_000_000_000)
                    throw ImageGenerationError.timeout
                }

                // 最初に完了したタスクの結果を返す
                if let result = try await group.next() {
                    group.cancelAll() // 残りのタスクをキャンセル
                    return result
                }

                return nil
            }
        } catch ImageGenerationError.timeout {
            print("⏱️ タイムアウト: ImageCreator APIが\(timeoutSeconds)秒以内に応答しませんでした")
            print("   → Core Graphicsフォールバックに移行します")
            cachedImageCreator = nil
            return nil
        } catch ImageCreator.Error.unsupportedLanguage {
            print("❌ サポートされていない言語が検出されました（日本語が含まれている可能性）")
            print("   元のテキスト: \(taskText)")
            print("   → Core Graphicsフォールバックに移行します")
            cachedImageCreator = nil
            return nil
        } catch ImageCreator.Error.notSupported {
            print("⚠️ このデバイスではImage Creationがサポートされていません")
            cachedImageCreator = nil
            return nil
        } catch let error as NSError where error.domain == "NSCocoaErrorDomain" && error.code == 4099 {
            print("🔌 ImageCreator接続エラー (Code=4099): システムサービスへの接続が中断されました")
            cachedImageCreator = nil

            if retryCount < maxRetries {
                print("🔄 リトライします... (試行 \(retryCount + 1)/\(maxRetries))")
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待機
                return await generateWithImageCreator(taskText: taskText, emoji: emoji, retryCount: retryCount + 1)
            } else {
                print("❌ リトライ上限に達しました。フォールバックに移行します。")
                return nil
            }
        } catch {
            print("❌ ImageCreator API エラー: \(error.localizedDescription)")
            print("   エラー詳細: \(error)")
            cachedImageCreator = nil
            return nil
        }
    }

    /// 画像生成の実処理（タイムアウト管理から分離）
    @available(iOS 18.4, *)
    private func performImageGeneration(taskText: String, emoji: String) async throws -> String? {
        let translatedText = translateTaskText(taskText)
        let prompt = createPromptForTask(taskText: translatedText, emoji: emoji)

        let creator: ImageCreator
        if let cached = cachedImageCreator as? ImageCreator {
            creator = cached
            print("♻️ キャッシュされたImageCreatorを使用します")
        } else {
            print("🆕 新しいImageCreatorを作成します")
            creator = try await ImageCreator()
            cachedImageCreator = creator as Any
            print("✅ ImageCreator作成完了")
        }

        let style = selectImageStyle(for: translatedText)
        print("🎨 スタイル選択: \(styleToString(style))")

        print("🖼️ 画像生成開始...")
        let images = creator.images(
            for: [.text(prompt)],
            style: style,
            limit: 1
        )

        for try await image in images {
            let cgImage = image.cgImage
            let uiImage = UIImage(cgImage: cgImage)
            print("✅ ImageCreator APIで画像生成成功")
            return saveImageToCache(uiImage, taskId: UUID().uuidString)
        }

        print("⚠️ 画像が生成されませんでした（空のストリーム）")
        return nil
    }

    /// スタイルを文字列に変換（デバッグ用）
    @available(iOS 18.4, *)
    private func styleToString(_ style: ImagePlaygroundStyle) -> String {
        switch style {
        case .illustration:
            return "illustration"
        case .sketch:
            return "sketch"
        case .animation:
            return "animation"
        default:
            return "unknown"
        }
    }

    /// 画像生成エラー
    enum ImageGenerationError: Error {
        case timeout
    }

    private func translateTaskText(_ taskText: String) -> String {
        let translatedText = TranslationService.shared.translateToEnglish(japaneseText: taskText)
        print("🔄 翻訳結果: \(taskText) → \(translatedText)")
        return translatedText
    }

    /// プロンプトに日本語が含まれているかチェック
    private func containsJapanese(_ text: String) -> Bool {
        let japaneseCharacterSet = CharacterSet(charactersIn: "\u{3040}"..."\u{309F}") // ひらがな
            .union(CharacterSet(charactersIn: "\u{30A0}"..."\u{30FF}")) // カタカナ
            .union(CharacterSet(charactersIn: "\u{4E00}"..."\u{9FAF}")) // 漢字
            .union(CharacterSet(charactersIn: "\u{3400}"..."\u{4DBF}")) // 漢字拡張A

        return text.unicodeScalars.contains { japaneseCharacterSet.contains($0) }
    }

    @available(iOS 18.4, *)
    private func selectImageStyle(for taskText: String) -> ImagePlaygroundStyle {
        let lowerText = taskText.lowercased()
        if lowerText.contains("draw") || lowerText.contains("art") || lowerText.contains("illustration") || lowerText.contains("paint") {
            return .illustration
        } else if lowerText.contains("memo") || lowerText.contains("note") || lowerText.contains("sketch") || lowerText.contains("draft") {
            return .sketch
        } else {
            return .animation
        }
    }

    private func createPromptForTask(taskText: String, emoji: String) -> String {
        var styleKeywords = [String]()
        let lowerText = taskText.lowercased()

        if lowerText.contains("study") || lowerText.contains("report") || lowerText.contains("assignment") || lowerText.contains("homework") || lowerText.contains("learn") || lowerText.contains("book") || lowerText.contains("textbook") {
            styleKeywords.append("books, study desk, academic atmosphere")
        } else if lowerText.contains("work") || lowerText.contains("meeting") || lowerText.contains("business") || lowerText.contains("office") || lowerText.contains("document") {
            styleKeywords.append("business, professional workspace, modern office")
        } else if lowerText.contains("exercise") || lowerText.contains("gym") || lowerText.contains("sport") || lowerText.contains("fitness") || lowerText.contains("run") || lowerText.contains("workout") || lowerText.contains("training") {
            styleKeywords.append("fitness, sports, active lifestyle")
        } else if lowerText.contains("cook") || lowerText.contains("food") || lowerText.contains("shopping") || lowerText.contains("grocery") || lowerText.contains("meal") {
            styleKeywords.append("food, cooking, kitchen")
        } else if lowerText.contains("music") || lowerText.contains("piano") || lowerText.contains("guitar") || lowerText.contains("instrument") || lowerText.contains("song") {
            styleKeywords.append("music, instruments, musical notes")
        } else if lowerText.contains("movie") || lowerText.contains("game") || lowerText.contains("fun") || lowerText.contains("hobby") {
            styleKeywords.append("entertainment, fun, creative hobby")
        } else if lowerText.contains("deadline") || lowerText.contains("urgent") || lowerText.contains("important") {
            styleKeywords.append("urgent, important task, focus")
        } else {
            styleKeywords.append("colorful, creative, abstract, daily task")
        }

        // プロンプトを構築（完全に英語のみ）
        let style = styleKeywords.joined(separator: ", ")
        var prompt = "A simple, clean illustration representing: \(style). Minimalist style with gradient background."

        // 最終チェック: プロンプトに日本語が含まれていないか確認
        if containsJapanese(prompt) {
            print("⚠️ プロンプトに日本語が含まれています。日本語を除去します。")
            // 日本語を除去
            prompt = TranslationService.shared.removeJapaneseCharacters(from: prompt)
            // 除去後に空になった場合はデフォルトプロンプトを使用
            if prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                prompt = "A simple, clean illustration representing daily task. Minimalist style with gradient background."
            }
        }

        print("📝 最終プロンプト: \(prompt)")
        return prompt
    }

    /// Core Graphicsを使用した画像生成（フォールバック）
    private func generateWithCoreGraphics(taskText: String, emoji: String) async -> String? {
        let size = CGSize(width: 400, height: 400)
        let gradientColors = selectGradientColors(for: taskText)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let cgContext = context.cgContext

            drawGradientBackground(in: cgContext, size: size, colors: gradientColors)
            drawTaskSpecificDecorations(for: taskText, in: cgContext, size: size)
            drawEmoji(emoji, in: cgContext, size: size)
            drawTaskText(taskText, in: cgContext, size: size)
            drawDecorations(in: cgContext, size: size)
        }

        return saveImageToCache(image, taskId: UUID().uuidString)
    }

    private func selectGradientColors(for taskText: String) -> [UIColor] {
        if taskText.contains("勉強") || taskText.contains("レポート") || taskText.contains("課題") {
            return [
                UIColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 1.0),
                UIColor(red: 0.2, green: 0.4, blue: 0.7, alpha: 1.0)
            ]
        } else if taskText.contains("仕事") || taskText.contains("会議") || taskText.contains("ミーティング") {
            return [
                UIColor(red: 0.3, green: 0.7, blue: 0.6, alpha: 1.0),
                UIColor(red: 0.2, green: 0.5, blue: 0.4, alpha: 1.0)
            ]
        } else if taskText.contains("運動") || taskText.contains("ジム") || taskText.contains("ランニング") {
            return [
                UIColor(red: 0.9, green: 0.5, blue: 0.3, alpha: 1.0),
                UIColor(red: 0.7, green: 0.3, blue: 0.2, alpha: 1.0)
            ]
        } else if taskText.contains("買い物") || taskText.contains("料理") {
            return [
                UIColor(red: 0.9, green: 0.7, blue: 0.4, alpha: 1.0),
                UIColor(red: 0.7, green: 0.5, blue: 0.3, alpha: 1.0)
            ]
        } else if taskText.contains("締切") || taskText.contains("期限") || taskText.contains("緊急") {
            return [
                UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0),
                UIColor(red: 0.7, green: 0.2, blue: 0.2, alpha: 1.0)
            ]
        } else {
            return [
                UIColor(red: 0.7, green: 0.5, blue: 0.9, alpha: 1.0),
                UIColor(red: 0.5, green: 0.3, blue: 0.7, alpha: 1.0)
            ]
        }
    }

    private func drawGradientBackground(in context: CGContext, size: CGSize, colors: [UIColor]) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let locations: [CGFloat] = [0.0, 1.0]
        let cgColors = colors.map { $0.cgColor } as CFArray

        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: cgColors, locations: locations) else {
            return
        }

        let startPoint = CGPoint(x: size.width / 2, y: 0)
        let endPoint = CGPoint(x: size.width / 2, y: size.height)

        context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
    }

    private func drawEmoji(_ emoji: String, in context: CGContext, size: CGSize) {
        let emojiFont = UIFont.systemFont(ofSize: 120)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: emojiFont,
            .foregroundColor: UIColor.white
        ]

        let emojiString = emoji as NSString
        let emojiSize = emojiString.size(withAttributes: attributes)
        let emojiRect = CGRect(
            x: (size.width - emojiSize.width) / 2,
            y: (size.height - emojiSize.height) / 2 - 20,
            width: emojiSize.width,
            height: emojiSize.height
        )

        emojiString.draw(in: emojiRect, withAttributes: attributes)
    }

    private func drawTaskText(_ text: String, in context: CGContext, size: CGSize) {
        let displayText = text.count > 20 ? String(text.prefix(20)) + "..." : text

        let textFont = UIFont.boldSystemFont(ofSize: 16)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: textFont,
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle
        ]

        let textString = displayText as NSString
        let textSize = textString.size(withAttributes: attributes)
        let textRect = CGRect(
            x: 20,
            y: size.height - textSize.height - 30,
            width: size.width - 40,
            height: textSize.height
        )

        textString.draw(in: textRect, withAttributes: attributes)
    }

    private func drawTaskSpecificDecorations(for taskText: String, in context: CGContext, size: CGSize) {
        if taskText.contains("数学") || taskText.contains("算数") {
            drawMathDecorations(in: context, size: size)
        } else if taskText.contains("英語") || taskText.contains("言語") {
            drawLanguageDecorations(in: context, size: size)
        } else if taskText.contains("勉強") || taskText.contains("レポート") || taskText.contains("課題") {
            drawStudyDecorations(in: context, size: size)
        } else if taskText.contains("仕事") || taskText.contains("会議") || taskText.contains("ミーティング") {
            drawBusinessDecorations(in: context, size: size)
        } else if taskText.contains("運動") || taskText.contains("ジム") || taskText.contains("ランニング") {
            drawSportsDecorations(in: context, size: size)
        } else if taskText.contains("料理") || taskText.contains("買い物") {
            drawCookingDecorations(in: context, size: size)
        } else if taskText.contains("音楽") || taskText.contains("ピアノ") || taskText.contains("ギター") {
            drawMusicDecorations(in: context, size: size)
        }
    }

    private func drawMathDecorations(in context: CGContext, size: CGSize) {
        let mathSymbols = ["π", "∫", "Σ", "√", "∞", "≈", "≠", "±", "÷", "×", "∂", "∇"]
        let font = UIFont.systemFont(ofSize: 24, weight: .light)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white.withAlphaComponent(0.25)
        ]

        for _ in 0..<12 {
            let symbol = mathSymbols.randomElement() ?? "π"
            let x = CGFloat.random(in: 20...size.width - 50)
            let y = CGFloat.random(in: 20...size.height - 50)
            let symbolString = symbol as NSString
            symbolString.draw(at: CGPoint(x: x, y: y), withAttributes: attributes)
        }

        context.setStrokeColor(UIColor.white.withAlphaComponent(0.1).cgColor)
        context.setLineWidth(1)
        for i in 0..<5 {
            let x = CGFloat(i) * (size.width / 4)
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: size.height))
        }
        context.strokePath()
    }

    private func drawLanguageDecorations(in context: CGContext, size: CGSize) {
        let letters = ["A", "B", "C", "Q", "W", "E", "R", "T", "Y", "U"]
        let font = UIFont.systemFont(ofSize: 30, weight: .ultraLight)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white.withAlphaComponent(0.2)
        ]

        for _ in 0..<10 {
            let letter = letters.randomElement() ?? "A"
            let x = CGFloat.random(in: 20...size.width - 50)
            let y = CGFloat.random(in: 20...size.height - 50)
            let letterString = letter as NSString
            letterString.draw(at: CGPoint(x: x, y: y), withAttributes: attributes)
        }
    }

    private func drawStudyDecorations(in context: CGContext, size: CGSize) {
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.15).cgColor)
        context.setLineWidth(1)
        for i in 0..<8 {
            let y = CGFloat(i) * (size.height / 7)
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: size.width, y: y))
        }
        context.strokePath()

        context.setStrokeColor(UIColor.white.withAlphaComponent(0.1).cgColor)
        context.setLineWidth(2)
        context.move(to: CGPoint(x: 40, y: 0))
        context.addLine(to: CGPoint(x: 40, y: size.height))
        context.strokePath()
    }

    private func drawBusinessDecorations(in context: CGContext, size: CGSize) {
        let font = UIFont.systemFont(ofSize: 20, weight: .light)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white.withAlphaComponent(0.2)
        ]

        let symbols = ["✓", "•", "→", "▸"]
        for i in 0..<6 {
            let symbol = symbols.randomElement() ?? "•"
            let x: CGFloat = 30
            let y = CGFloat(i) * 45 + 20
            let symbolString = symbol as NSString
            symbolString.draw(at: CGPoint(x: x, y: y), withAttributes: attributes)
        }

        context.setStrokeColor(UIColor.white.withAlphaComponent(0.15).cgColor)
        context.setLineWidth(2)
        context.move(to: CGPoint(x: size.width * 0.6, y: size.height * 0.7))
        context.addLine(to: CGPoint(x: size.width * 0.7, y: size.height * 0.4))
        context.addLine(to: CGPoint(x: size.width * 0.8, y: size.height * 0.5))
        context.addLine(to: CGPoint(x: size.width * 0.9, y: size.height * 0.2))
        context.strokePath()
    }

    private func drawSportsDecorations(in context: CGContext, size: CGSize) {
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.2).cgColor)
        context.setLineWidth(3)
        for _ in 0..<4 {
            let centerX = CGFloat.random(in: 0...size.width)
            let centerY = CGFloat.random(in: 0...size.height)
            let radius = CGFloat.random(in: 30...80)
            context.addArc(center: CGPoint(x: centerX, y: centerY), radius: radius, startAngle: 0, endAngle: .pi * 1.5, clockwise: false)
        }
        context.strokePath()
    }

    private func drawCookingDecorations(in context: CGContext, size: CGSize) {
        context.setFillColor(UIColor.white.withAlphaComponent(0.15).cgColor)
        for _ in 0..<8 {
            let x = CGFloat.random(in: 0...size.width)
            let y = CGFloat.random(in: 0...size.height)
            let radius = CGFloat.random(in: 15...35)
            context.fillEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
        }
    }

    private func drawMusicDecorations(in context: CGContext, size: CGSize) {
        let musicSymbols = ["♪", "♫", "♬", "𝄞"]
        let font = UIFont.systemFont(ofSize: 28, weight: .light)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white.withAlphaComponent(0.25)
        ]

        for _ in 0..<10 {
            let symbol = musicSymbols.randomElement() ?? "♪"
            let x = CGFloat.random(in: 20...size.width - 50)
            let y = CGFloat.random(in: 20...size.height - 50)
            let symbolString = symbol as NSString
            symbolString.draw(at: CGPoint(x: x, y: y), withAttributes: attributes)
        }

        context.setStrokeColor(UIColor.white.withAlphaComponent(0.15).cgColor)
        context.setLineWidth(1)
        for i in 0..<5 {
            let y = size.height * 0.3 + CGFloat(i) * 12
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: size.width, y: y))
        }
        context.strokePath()
    }

    private func drawDecorations(in context: CGContext, size: CGSize) {
        context.setFillColor(UIColor.white.withAlphaComponent(0.1).cgColor)
        context.fillEllipse(in: CGRect(x: -50, y: -50, width: 150, height: 150))
        context.fillEllipse(in: CGRect(x: size.width - 100, y: size.height - 100, width: 150, height: 150))

        context.setFillColor(UIColor.white.withAlphaComponent(0.2).cgColor)
        for _ in 0..<15 {
            let x = CGFloat.random(in: 0...size.width)
            let y = CGFloat.random(in: 0...size.height)
            let radius = CGFloat.random(in: 2...6)
            context.fillEllipse(in: CGRect(x: x, y: y, width: radius, height: radius))
        }
    }

    private func saveImageToCache(_ image: UIImage, taskId: String) -> String? {
        guard let data = image.pngData() else {
            return nil
        }

        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        guard let cacheURL = cacheDirectory else {
            return nil
        }

        let fileName = "task_\(taskId).png"
        let fileURL = cacheURL.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            print("画像の保存に失敗しました: \(error.localizedDescription)")
            return nil
        }
    }

    func clearCache() {
        guard let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return
        }

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            let taskImageURLs = fileURLs.filter { $0.lastPathComponent.hasPrefix("task_") }

            for fileURL in taskImageURLs {
                try FileManager.default.removeItem(at: fileURL)
            }

            print("キャッシュをクリアしました: \(taskImageURLs.count)個のファイル")
        } catch {
            print("キャッシュのクリアに失敗しました: \(error.localizedDescription)")
        }
    }
}

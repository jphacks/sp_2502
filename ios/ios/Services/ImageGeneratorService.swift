//
//  ImageGeneratorService.swift
//  ios
//

import UIKit
import CoreGraphics
import ImagePlayground

class ImageGeneratorService {
    static let shared = ImageGeneratorService()

    private init() {}

    /// タスクテキストと絵文字から画像を生成してローカルに保存
    func generateTaskImage(taskText: String, emoji: String) async -> String? {
        // iOS 18.4以降でImageCreator APIが利用可能な場合
        if #available(iOS 18.4, *) {
            if let imagePath = await generateWithImageCreator(taskText: taskText, emoji: emoji) {
                return imagePath
            }
            // ImageCreator APIが失敗した場合はフォールバック
            print("⚠️ ImageCreator APIが失敗しました。フォールバック処理を実行します。")
        }

        // iOS 18.4未満、または ImageCreator API失敗時のフォールバック
        return await generateWithCoreGraphics(taskText: taskText, emoji: emoji)
    }

    /// ImageCreator APIを使用した画像生成 (iOS 18.4+)
    @available(iOS 18.4, *)
    private func generateWithImageCreator(taskText: String, emoji: String) async -> String? {
        do {
            // プロンプトを作成
            let prompt = createPromptForTask(taskText: taskText, emoji: emoji)

            // ImageCreatorを初期化（async throws）
            let creator = try await ImageCreator()

            // スタイルを選択（タスクの種類に応じて）
            let style = selectImageStyle(for: taskText)

            // 画像を生成（AsyncSequenceで返される）
            let images = creator.images(
                for: [.text(prompt)],
                style: style,
                limit: 1
            )

            // 最初の画像を取得
            for try await image in images {
                let cgImage = image.cgImage
                let uiImage = UIImage(cgImage: cgImage)
                return saveImageToCache(uiImage, taskId: UUID().uuidString)
            }

            return nil
        } catch ImageCreator.Error.notSupported {
            print("⚠️ このデバイスではImage Creationがサポートされていません")
            return nil
        } catch {
            print("❌ ImageCreator API エラー: \(error.localizedDescription)")
            return nil
        }
    }

    /// タスク内容に応じた画像スタイルを選択
    @available(iOS 18.4, *)
    private func selectImageStyle(for taskText: String) -> ImagePlaygroundStyle {
        // タスクの種類に応じてスタイルを選択
        if taskText.contains("絵") || taskText.contains("アート") || taskText.contains("イラスト") {
            return .illustration
        } else if taskText.contains("メモ") || taskText.contains("スケッチ") {
            return .sketch
        } else {
            // デフォルトはアニメーションスタイル
            return .animation
        }
    }

    /// タスクテキストから画像生成用のプロンプトを作成
    private func createPromptForTask(taskText: String, emoji: String) -> String {
        // タスクの内容に応じたビジュアルスタイルを決定
        var styleKeywords = [String]()

        if taskText.contains("勉強") || taskText.contains("レポート") || taskText.contains("課題") {
            styleKeywords.append("books, study desk, academic atmosphere")
        } else if taskText.contains("仕事") || taskText.contains("会議") {
            styleKeywords.append("business, professional workspace, modern office")
        } else if taskText.contains("運動") || taskText.contains("ジム") {
            styleKeywords.append("fitness, sports, active lifestyle")
        } else if taskText.contains("料理") || taskText.contains("買い物") {
            styleKeywords.append("food, cooking, kitchen")
        } else if taskText.contains("音楽") {
            styleKeywords.append("music, instruments, musical notes")
        } else {
            styleKeywords.append("colorful, creative, abstract")
        }

        // プロンプトを構築
        let style = styleKeywords.joined(separator: ", ")
        return "A simple, clean illustration representing: \(style). Minimalist style with gradient background. Include \(emoji) emoji theme."
    }

    /// Core Graphicsを使用した画像生成（フォールバック）
    private func generateWithCoreGraphics(taskText: String, emoji: String) async -> String? {
        // 画像サイズ
        let size = CGSize(width: 400, height: 300)

        // グラデーション色を選択（タスクの種類に応じて）
        let gradientColors = selectGradientColors(for: taskText)

        // UIGraphicsImageRendererを使用して画像を生成
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let cgContext = context.cgContext

            // グラデーション背景を描画
            drawGradientBackground(in: cgContext, size: size, colors: gradientColors)

            // タスク内容に応じた装飾を追加
            drawTaskSpecificDecorations(for: taskText, in: cgContext, size: size)

            // 絵文字を大きく中央に描画
            drawEmoji(emoji, in: cgContext, size: size)

            // タスクテキストを下部に描画
            drawTaskText(taskText, in: cgContext, size: size)

            // 基本的な装飾要素を追加
            drawDecorations(in: cgContext, size: size)
        }

        // 画像を一時ディレクトリに保存
        return saveImageToCache(image, taskId: UUID().uuidString)
    }

    // グラデーションの色を選択
    private func selectGradientColors(for taskText: String) -> [UIColor] {
        // キーワードに基づいて色を選択
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
            // デフォルト（紫系）
            return [
                UIColor(red: 0.7, green: 0.5, blue: 0.9, alpha: 1.0),
                UIColor(red: 0.5, green: 0.3, blue: 0.7, alpha: 1.0)
            ]
        }
    }

    // グラデーション背景を描画
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

    // 絵文字を描画
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

    // タスクテキストを描画
    private func drawTaskText(_ text: String, in context: CGContext, size: CGSize) {
        // テキストを適切な長さに省略
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

    // タスク内容に応じた装飾を描画
    private func drawTaskSpecificDecorations(for taskText: String, in context: CGContext, size: CGSize) {
        // 数学・勉強関連
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

    // 数学関連の装飾
    private func drawMathDecorations(in context: CGContext, size: CGSize) {
        let mathSymbols = ["π", "∫", "Σ", "√", "∞", "≈", "≠", "±", "÷", "×", "∂", "∇"]
        let font = UIFont.systemFont(ofSize: 24, weight: .light)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white.withAlphaComponent(0.25)
        ]

        // ランダムに数式記号を配置
        for _ in 0..<12 {
            let symbol = mathSymbols.randomElement() ?? "π"
            let x = CGFloat.random(in: 20...size.width - 50)
            let y = CGFloat.random(in: 20...size.height - 50)
            let symbolString = symbol as NSString
            symbolString.draw(at: CGPoint(x: x, y: y), withAttributes: attributes)
        }

        // グリッド線を描画
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.1).cgColor)
        context.setLineWidth(1)
        for i in 0..<5 {
            let x = CGFloat(i) * (size.width / 4)
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: size.height))
        }
        context.strokePath()
    }

    // 言語学習関連の装飾
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

    // 一般的な勉強関連の装飾
    private func drawStudyDecorations(in context: CGContext, size: CGSize) {
        // ノートの罫線風
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.15).cgColor)
        context.setLineWidth(1)
        for i in 0..<8 {
            let y = CGFloat(i) * (size.height / 7)
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: size.width, y: y))
        }
        context.strokePath()

        // マーカー線
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.1).cgColor)
        context.setLineWidth(2)
        context.move(to: CGPoint(x: 40, y: 0))
        context.addLine(to: CGPoint(x: 40, y: size.height))
        context.strokePath()
    }

    // 仕事・ビジネス関連の装飾
    private func drawBusinessDecorations(in context: CGContext, size: CGSize) {
        // チェックマークや箇条書き風
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

        // グラフ風の線
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.15).cgColor)
        context.setLineWidth(2)
        context.move(to: CGPoint(x: size.width * 0.6, y: size.height * 0.7))
        context.addLine(to: CGPoint(x: size.width * 0.7, y: size.height * 0.4))
        context.addLine(to: CGPoint(x: size.width * 0.8, y: size.height * 0.5))
        context.addLine(to: CGPoint(x: size.width * 0.9, y: size.height * 0.2))
        context.strokePath()
    }

    // 運動・スポーツ関連の装飾
    private func drawSportsDecorations(in context: CGContext, size: CGSize) {
        // ダイナミックな円弧
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

    // 料理関連の装飾
    private func drawCookingDecorations(in context: CGContext, size: CGSize) {
        // 円形のパターン（食材風）
        context.setFillColor(UIColor.white.withAlphaComponent(0.15).cgColor)
        for _ in 0..<8 {
            let x = CGFloat.random(in: 0...size.width)
            let y = CGFloat.random(in: 0...size.height)
            let radius = CGFloat.random(in: 15...35)
            context.fillEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
        }
    }

    // 音楽関連の装飾
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

        // 五線譜風の線
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.15).cgColor)
        context.setLineWidth(1)
        for i in 0..<5 {
            let y = size.height * 0.3 + CGFloat(i) * 12
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: size.width, y: y))
        }
        context.strokePath()
    }

    // 装飾要素を描画
    private func drawDecorations(in context: CGContext, size: CGSize) {
        // 半透明の円を描画
        context.setFillColor(UIColor.white.withAlphaComponent(0.1).cgColor)
        context.fillEllipse(in: CGRect(x: -50, y: -50, width: 150, height: 150))
        context.fillEllipse(in: CGRect(x: size.width - 100, y: size.height - 100, width: 150, height: 150))

        // 小さな点を描画
        context.setFillColor(UIColor.white.withAlphaComponent(0.2).cgColor)
        for _ in 0..<15 {
            let x = CGFloat.random(in: 0...size.width)
            let y = CGFloat.random(in: 0...size.height)
            let radius = CGFloat.random(in: 2...6)
            context.fillEllipse(in: CGRect(x: x, y: y, width: radius, height: radius))
        }
    }

    // 画像をキャッシュディレクトリに保存
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

    /// キャッシュされた画像を削除
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

import SwiftUI

/// タスクカード専用のView
struct TaskCardView: View {
    let imageURL: String
    let emoji: String?

    var body: some View {
        ZStack {
            // 背景画像またはデフォルト背景
            if let uiImage = loadImageFromPath(imageURL) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else {
                CardConstants.Colors.taskCardBackground
            }

            // 絵文字表示（中央に配置）
            if let emoji = emoji {
                Text(emoji)
                    .font(.system(size: CardConstants.Typography.emojiSize))
            }
        }
    }

    /// ローカルパスから画像を読み込む
    private func loadImageFromPath(_ path: String) -> UIImage? {
        guard FileManager.default.fileExists(atPath: path) else {
            return nil
        }
        return UIImage(contentsOfFile: path)
    }
}

#Preview {
    TaskCardView(
        imageURL: "/path/to/image.png",
        emoji: "📝"
    )
    .aspectRatio(CardConstants.Layout.aspectRatio, contentMode: .fit)
    .padding()
}

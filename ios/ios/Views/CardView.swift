//
//  CardView.swift
//  ios
//

import SwiftUI

struct CardView: View {
    let card: Card

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.6, green: 0.6, blue: 0.6),
                            Color(red: 0.2, green: 0.2, blue: 0.2)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)

            VStack(spacing: 12) {
                // 画像エリア（中央配置）
                Group {
                    if card.isTaskCard {
                        // タスクカード用の表示
                        taskCardContent
                    } else if card.isLocalImage {
                        // ローカル画像の表示
                        Image(card.imageURL)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        // リモート画像の表示
                        AsyncImage(url: URL(string: card.imageURL)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .cornerRadius(15)
                .padding(16)

                if let title = card.title, !card.isTaskCard {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
            }
        }
    }

    // タスクカード用のコンテンツ
    @ViewBuilder
    private var taskCardContent: some View {
        ZStack {
            // 生成された画像を表示
            if let uiImage = loadImageFromPath(card.imageURL) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else {
                // フォールバック
                Color.purple.opacity(0.3)
            }

            // 絵文字をオーバーレイ
            if let emoji = card.emoji {
                VStack {
                    Spacer()
                    Text(emoji)
                        .font(.system(size: 60))
                        .padding(.bottom, 8)
                }
            }
        }
    }

    // ローカルパスから画像を読み込む
    private func loadImageFromPath(_ path: String) -> UIImage? {
        guard FileManager.default.fileExists(atPath: path) else {
            return nil
        }
        return UIImage(contentsOfFile: path)
    }
}

#Preview {
    CardView(card: Card(
        id: "1",
        imageURL: "https://via.placeholder.com/300",
        title: "Sample Card",
        description: nil,
        isLocalImage: false
    ))
}

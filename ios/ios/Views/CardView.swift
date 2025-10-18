//
//  CardView.swift
//  ios
//

import SwiftUI

struct CardView: View {
    let card: Card

    var body: some View {
        ZStack {
            // 外側カード台座（グレー、3D効果）
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.55, green: 0.55, blue: 0.55),
                            Color(red: 0.35, green: 0.35, blue: 0.35)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)

            // 内側の紙風レイヤー（ベージュ）
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.96, green: 0.93, blue: 0.85),
                            Color(red: 0.92, green: 0.88, blue: 0.78)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(12)

            VStack(alignment: .leading, spacing: 0) {
                // 画像エリア（金色フレーム装飾付き）
                ZStack {
                    // 金色フレーム装飾（ペイント風）
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.85, green: 0.65, blue: 0.13),
                                    Color(red: 0.72, green: 0.52, blue: 0.04)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 8)
                        .offset(y: -4)

                    // 画像コンテンツ
                    Group {
                        if card.isTaskCard {
                            taskCardContent
                        } else if card.isLocalImage {
                            Image(card.imageURL)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
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
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1.0, contentMode: .fill)
                    .clipped()
                    .cornerRadius(4)
                }
                .padding(.horizontal, 28)
                .padding(.top, 28)

                Spacer()

                // テキストエリア（左下配置、白文字）
                if let title = card.title {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)

                        if let description = card.description {
                            Text(description)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 24)
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

import SwiftUI

struct CardView: View {
    let card: Card

    var body: some View {
        ZStack {
            // 外側カード台座（グレー、3D効果）
            RoundedRectangle(cornerRadius: CardConstants.Layout.CornerRadius.outer)
                .fill(CardConstants.Colors.outerCardGradient)
                .shadow(
                    color: CardConstants.Shadow.outerPrimary.color,
                    radius: CardConstants.Shadow.outerPrimary.radius,
                    x: CardConstants.Shadow.outerPrimary.x,
                    y: CardConstants.Shadow.outerPrimary.y
                )
                .shadow(
                    color: CardConstants.Shadow.outerSecondary.color,
                    radius: CardConstants.Shadow.outerSecondary.radius,
                    x: CardConstants.Shadow.outerSecondary.x,
                    y: CardConstants.Shadow.outerSecondary.y
                )

            // 内側の紙風レイヤー（ベージュ）
            RoundedRectangle(cornerRadius: CardConstants.Layout.CornerRadius.inner)
                .fill(CardConstants.Colors.innerCardGradient)
                .padding(CardConstants.Layout.Padding.innerCard)

            // 画像エリア（金色フレーム装飾付き、カード全体に配置）
            ZStack(alignment: .bottomLeading) {
                // 金色フレーム装飾（ペイント風）
                VStack {
                    RoundedRectangle(cornerRadius: CardConstants.Layout.CornerRadius.goldFrame)
                        .fill(CardConstants.Colors.goldFrameGradient)
                        .frame(height: CardConstants.Layout.Frame.goldFrameHeight)
                        .padding(.horizontal, CardConstants.Layout.Padding.goldFrameHorizontal)
                        .padding(.top, CardConstants.Layout.Padding.goldFrameTop)
                    Spacer()
                }

                ZStack {
                    Group {
                        if card.isTaskCard {
                            TaskCardView(imageURL: card.imageURL, emoji: card.emoji)
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
                    .clipped()

                    // テキスト視認性向上のためのグラデーションオーバーレイ
                    CardConstants.Colors.textOverlayGradient
                }
                .cornerRadius(CardConstants.Layout.CornerRadius.image)
                .padding(.horizontal, CardConstants.Layout.Padding.imageHorizontal)
                .padding(.top, CardConstants.Layout.Padding.imageTop)
                .padding(.bottom, CardConstants.Layout.Padding.imageBottom)

                // テキストエリア（画像の上に重ねて配置、左下配置、白文字）
                if let title = card.title {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(
                                size: CardConstants.Typography.titleSize,
                                weight: CardConstants.Typography.titleWeight
                            ))
                            .foregroundColor(CardConstants.Typography.titleColor)
                            .shadow(
                                color: CardConstants.Shadow.text.color,
                                radius: CardConstants.Shadow.text.radius,
                                x: CardConstants.Shadow.text.x,
                                y: CardConstants.Shadow.text.y
                            )

                        if let description = card.description {
                            Text(description)
                                .font(.system(
                                    size: CardConstants.Typography.descriptionSize,
                                    weight: CardConstants.Typography.descriptionWeight
                                ))
                                .foregroundColor(CardConstants.Typography.descriptionColor)
                                .shadow(
                                    color: CardConstants.Shadow.text.color,
                                    radius: CardConstants.Shadow.text.radius,
                                    x: CardConstants.Shadow.text.x,
                                    y: CardConstants.Shadow.text.y
                                )
                        }
                    }
                    .padding(.horizontal, CardConstants.Layout.Padding.textHorizontal)
                    .padding(.bottom, CardConstants.Layout.Padding.textBottom)
                }
            }
        }
        .aspectRatio(CardConstants.Layout.aspectRatio, contentMode: .fit)
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

import SwiftUI

/// カード関連の定数を集約
enum CardConstants {

    // MARK: - Layout

    enum Layout {
        /// カードのアスペクト比
        static let aspectRatio: CGFloat = 3.0 / 4.0

        /// 角丸の半径
        enum CornerRadius {
            static let outer: CGFloat = 20
            static let inner: CGFloat = 16
            static let goldFrame: CGFloat = 8
            static let image: CGFloat = 4
        }

        /// パディング
        enum Padding {
            static let innerCard: CGFloat = 12
            static let imageHorizontal: CGFloat = 28
            static let imageTop: CGFloat = 32
            static let imageBottom: CGFloat = 28
            static let goldFrameHorizontal: CGFloat = 28
            static let goldFrameTop: CGFloat = 24
            static let textHorizontal: CGFloat = 48
            static let textBottom: CGFloat = 48
        }

        /// フレームサイズ
        enum Frame {
            static let goldFrameHeight: CGFloat = 8
        }
    }

    // MARK: - Colors

    enum Colors {
        /// 外側カード台座のグラデーション
        static let outerCardGradient = LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.55, green: 0.55, blue: 0.55),
                Color(red: 0.35, green: 0.35, blue: 0.35)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// 内側の紙風レイヤーのグラデーション
        static let innerCardGradient = LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.96, green: 0.93, blue: 0.85),
                Color(red: 0.92, green: 0.88, blue: 0.78)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )

        /// 金色フレーム装飾のグラデーション
        static let goldFrameGradient = LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.85, green: 0.65, blue: 0.13),
                Color(red: 0.72, green: 0.52, blue: 0.04)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// テキスト視認性向上のためのグラデーションオーバーレイ
        static let textOverlayGradient = LinearGradient(
            gradient: Gradient(colors: [
                Color.black.opacity(0.75),
                Color.clear,
                Color.clear
            ]),
            startPoint: .bottom,
            endPoint: .top
        )

        /// タスクカードの背景色
        static let taskCardBackground = Color.purple.opacity(0.3)
    }

    // MARK: - Shadows

    enum Shadow {
        struct Configuration {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }

        static let outerPrimary = Configuration(
            color: .black.opacity(0.5),
            radius: 20,
            x: 0,
            y: 10
        )

        static let outerSecondary = Configuration(
            color: .black.opacity(0.3),
            radius: 10,
            x: 0,
            y: 5
        )

        static let text = Configuration(
            color: .black.opacity(0.5),
            radius: 2,
            x: 0,
            y: 1
        )
    }

    // MARK: - Typography

    enum Typography {
        static let titleSize: CGFloat = 24
        static let titleWeight: Font.Weight = .bold

        static let descriptionSize: CGFloat = 16
        static let descriptionWeight: Font.Weight = .medium

        static let emojiSize: CGFloat = 60

        static let titleColor: Color = .white
        static let descriptionColor: Color = .white.opacity(0.9)
    }

    // MARK: - Swipe

    enum Swipe {
        /// スワイプの閾値（この距離を超えるとスワイプとして認識）
        static let threshold: CGFloat = 100

        /// スワイプ時の回転角度の係数
        static let rotationFactor: CGFloat = 20

        /// ドラッグ中の透明度
        static let draggingOpacity: Double = 0.8

        /// スワイプアニメーションの継続時間
        static let animationDuration: Double = 0.3

        /// 画面外への移動距離
        static let exitOffset: CGFloat = 500

        /// スワイプ方向ごとの設定
        struct DirectionConfig {
            let color: Color
            let icon: String
            let text: String
        }

        static func config(for direction: SwipeDirection) -> DirectionConfig {
            switch direction {
            case .up:
                return DirectionConfig(
                    color: .red,
                    icon: "trash",
                    text: "Delete"
                )
            case .right:
                return DirectionConfig(
                    color: .green,
                    icon: "hand.thumbsup.fill",
                    text: "Like"
                )
            case .cut, .left:
                return DirectionConfig(
                    color: Color(red: 1.0, green: 0.6, blue: 0.4),
                    icon: "scissors",
                    text: "Cut"
                )
            }
        }
    }
}

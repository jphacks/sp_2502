//
//  SwipeableCardView.swift
//  ios
//

import SwiftUI

struct SwipeableCardView: View {
    let card: Card
    let onSwipe: (SwipeDirection) -> Void
    let onSwipeProgress: ((CGFloat) -> Void)?
    let onSwipeDirectionChange: ((SwipeDirection?) -> Void)?

    @State private var offset = CGSize.zero
    @State private var isDragging = false

    private let swipeThreshold: CGFloat = 100

    init(
        card: Card,
        onSwipe: @escaping (SwipeDirection) -> Void,
        onSwipeProgress: ((CGFloat) -> Void)? = nil,
        onSwipeDirectionChange: ((SwipeDirection?) -> Void)? = nil
    ) {
        self.card = card
        self.onSwipe = onSwipe
        self.onSwipeProgress = onSwipeProgress
        self.onSwipeDirectionChange = onSwipeDirectionChange
    }

    var body: some View {
        CardView(card: card)
            .offset(offset)
            .rotationEffect(.degrees(Double(offset.width / 20)))
            .opacity(isDragging ? 0.8 : 1.0)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        offset = gesture.translation
                        isDragging = true

                        // スワイプ進行度を計算（0.0〜1.0）
                        let distance = max(abs(gesture.translation.width), abs(gesture.translation.height))
                        let progress = min(distance / (swipeThreshold * 2), 1.0)
                        onSwipeProgress?(progress)

                        // スワイプ方向を通知
                        if abs(offset.width) > swipeThreshold || abs(offset.height) > swipeThreshold {
                            let direction = determineDirection(offset: offset)
                            onSwipeDirectionChange?(direction)
                        } else {
                            onSwipeDirectionChange?(nil)
                        }
                    }
                    .onEnded { gesture in
                        isDragging = false
                        onSwipeDirectionChange?(nil)
                        handleSwipeEnd(translation: gesture.translation)
                    }
            )
            .animation(.spring(), value: offset)
    }

    private func handleSwipeEnd(translation: CGSize) {
        let horizontalSwipe = abs(translation.width) > abs(translation.height)

        if horizontalSwipe {
            if abs(translation.width) > swipeThreshold {
                let direction: SwipeDirection = translation.width > 0 ? .right : .cut
                performSwipe(direction: direction)
            } else {
                offset = .zero
                onSwipeProgress?(0) // スワイプキャンセル時は進行度をリセット
            }
        } else {
            // 上向きのスワイプのみ許可
            if translation.height < -swipeThreshold {
                performSwipe(direction: .up)
            } else {
                offset = .zero
                onSwipeProgress?(0) // スワイプキャンセル時は進行度をリセット
            }
        }
    }

    private func performSwipe(direction: SwipeDirection) {
        let exitOffset: CGSize
        switch direction {
        case .up:
            exitOffset = CGSize(width: 0, height: -500)
        case .left:
            exitOffset = CGSize(width: -500, height: 0)
        case .right:
            exitOffset = CGSize(width: 500, height: 0)
        case .cut:
            exitOffset = CGSize(width: -500, height: 0)
        }

        withAnimation(.easeOut(duration: 0.3)) {
            offset = exitOffset
            onSwipeProgress?(1.0) // スワイプ完了時は進行度を最大に
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onSwipe(direction)
            onSwipeProgress?(0) // スワイプ後は進行度をリセット
            // offset = .zero を削除 - カードはそのまま画面外に留まる
        }
    }

    private func determineDirection(offset: CGSize) -> SwipeDirection? {
        let horizontalSwipe = abs(offset.width) > abs(offset.height)

        if horizontalSwipe {
            return offset.width > 0 ? .right : .cut
        } else {
            // 上向きのスワイプのみ表示
            return offset.height < 0 ? .up : nil
        }
    }

    private func iconForDirection(_ direction: SwipeDirection) -> String {
        switch direction {
        case .up:
            return "trash"
        case .right:
            return "hand.thumbsup.fill"
        case .cut:
            return "scissors"
        case .left:
            return "scissors"
        }
    }

    private func textForDirection(_ direction: SwipeDirection) -> String {
        switch direction {
        case .up:
            return "Delete"
        case .right:
            return "Like"
        case .cut:
            return "Cut"
        case .left:
            return "Cut"
        }
    }

    private func colorForDirection(_ direction: SwipeDirection) -> Color {
        switch direction {
        case .up:
            return .red
        case .right:
            return .green
        case .cut:
            return Color(red: 1.0, green: 0.6, blue: 0.4)
        case .left:
            return Color(red: 1.0, green: 0.6, blue: 0.4)
        }
    }
}

#Preview {
    SwipeableCardView(card: Card(
        id: "1",
        imageURL: "https://via.placeholder.com/300",
        title: "Sample Card",
        description: nil
    )) { direction in
        print("Swiped \(direction)")
    }
}

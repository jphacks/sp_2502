//
//  SwipeableCardView.swift
//  ios
//

import SwiftUI

struct SwipeableCardView: View {
    let card: Card
    let onSwipe: (SwipeDirection) -> Void

    @State private var offset = CGSize.zero
    @State private var isDragging = false

    private let swipeThreshold: CGFloat = 100

    var body: some View {
        CardView(card: card)
            .offset(offset)
            .rotationEffect(.degrees(Double(offset.width / 20)))
            .opacity(isDragging ? 0.8 : 1.0)
            .overlay(
                overlayView
            )
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        offset = gesture.translation
                        isDragging = true
                    }
                    .onEnded { gesture in
                        isDragging = false
                        handleSwipeEnd(translation: gesture.translation)
                    }
            )
            .animation(.spring(), value: offset)
    }

    private var overlayView: some View {
        ZStack {
            if abs(offset.width) > swipeThreshold / 2 || abs(offset.height) > swipeThreshold / 2 {
                let direction = determineDirection(offset: offset)
                overlayIndicator(for: direction)
            }
        }
    }

    private func overlayIndicator(for direction: SwipeDirection?) -> some View {
        Group {
            if let direction = direction {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(colorForDirection(direction).opacity(0.3))

                    VStack {
                        Image(systemName: iconForDirection(direction))
                            .font(.system(size: 60))
                            .foregroundColor(colorForDirection(direction))
                        Text(textForDirection(direction))
                            .font(.headline)
                            .foregroundColor(colorForDirection(direction))
                    }
                }
                .padding(20)
            }
        }
    }

    private func handleSwipeEnd(translation: CGSize) {
        let horizontalSwipe = abs(translation.width) > abs(translation.height)

        if horizontalSwipe {
            if abs(translation.width) > swipeThreshold {
                let direction: SwipeDirection = translation.width > 0 ? .right : .left
                performSwipe(direction: direction)
            } else {
                offset = .zero
            }
        } else {
            if abs(translation.height) > swipeThreshold {
                let direction: SwipeDirection = translation.height > 0 ? .down : .up
                performSwipe(direction: direction)
            } else {
                offset = .zero
            }
        }
    }

    private func performSwipe(direction: SwipeDirection) {
        let exitOffset: CGSize
        switch direction {
        case .up:
            exitOffset = CGSize(width: 0, height: -500)
        case .down:
            exitOffset = CGSize(width: 0, height: 500)
        case .left:
            exitOffset = CGSize(width: -500, height: 0)
        case .right:
            exitOffset = CGSize(width: 500, height: 0)
        }

        withAnimation(.easeOut(duration: 0.3)) {
            offset = exitOffset
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onSwipe(direction)
            offset = .zero
        }
    }

    private func determineDirection(offset: CGSize) -> SwipeDirection? {
        let horizontalSwipe = abs(offset.width) > abs(offset.height)

        if horizontalSwipe {
            return offset.width > 0 ? .right : .left
        } else {
            return offset.height > 0 ? .down : .up
        }
    }

    private func iconForDirection(_ direction: SwipeDirection) -> String {
        switch direction {
        case .up:
            return "trash"
        case .down:
            return "forward.end"
        case .left:
            return "arrow.uturn.backward"
        case .right:
            return "hand.thumbsup.fill"
        }
    }

    private func textForDirection(_ direction: SwipeDirection) -> String {
        switch direction {
        case .up:
            return "Delete"
        case .down:
            return "Skip"
        case .left:
            return "Undo"
        case .right:
            return "Like"
        }
    }

    private func colorForDirection(_ direction: SwipeDirection) -> Color {
        switch direction {
        case .up:
            return .red
        case .down:
            return .orange
        case .left:
            return .blue
        case .right:
            return .green
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

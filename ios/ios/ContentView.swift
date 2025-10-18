//
//  ContentView.swift
//  ios
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CardViewModel()
    @StateObject private var speechViewModel = SpeechRecognizerViewModel()
    @State private var swipeProgress: CGFloat = 0

    var body: some View {
        ZStack {
            Color(red: 0.95, green: 0.95, blue: 0.95)
                .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView("Loading cards...")
                    .font(.headline)
            } else if viewModel.isGeneratingCard {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("カードを生成中...")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.headline)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Retry") {
                        Task {
                            await viewModel.loadCards()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if let card = viewModel.currentCard {
                VStack(spacing: 0) {
                    actionButton(
                        icon: "trash",
                        color: .red,
                        action: { viewModel.handleDelete() }
                    )
                    .padding(.bottom, 30)

                    HStack(spacing: 40) {
                        actionButton(
                            icon: "arrow.uturn.backward",
                            color: .blue,
                            action: { viewModel.handleUndo() }
                        )

                        // カードスタック表示
                        GeometryReader { geometry in
                            cardStackView(currentCard: card, screenSize: geometry.size)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }

                        actionButton(
                            icon: "hand.thumbsup.fill",
                            color: .green,
                            action: { viewModel.handleLike() }
                        )
                    }

                    actionButton(
                        icon: "forward.end",
                        color: .orange,
                        action: { viewModel.handleSkip() }
                    )
                    .padding(.top, 30)
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No more cards")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
            }

            // マイク入力ボタン（右下に配置）
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    micButton
                        .padding(.trailing, 20)
                        .padding(.bottom, 50)
                }
            }
        }
        .task {
            await viewModel.loadCards()

            // 音声認識完了時のコールバックを設定
            speechViewModel.onRecognitionCompleted = { recognizedText in
                Task { @MainActor in
                    await viewModel.addTaskCard(taskText: recognizedText)
                }
            }
        }
    }

    private func actionButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
        }
    }

    @ViewBuilder
    private func cardStackView(currentCard: Card, screenSize: CGSize) -> some View {
        let stackCards = [currentCard] + viewModel.getUpcomingCards(count: 2)

        // カードサイズを3:2の比率で設定（画面幅の75%基準）
        let cardWidth = screenSize.width * 0.75
        let cardHeight = cardWidth * (2.0 / 3.0)

        ZStack {
            ForEach(Array(stackCards.enumerated()), id: \.element.id) { index, stackCard in
                Group {
                    if index == 0 {
                        SwipeableCardView(card: stackCard, onSwipe: { direction in
                            viewModel.handleSwipe(direction: direction)
                        }, onSwipeProgress: { progress in
                            swipeProgress = progress
                        })
                    } else {
                        CardView(card: stackCard)
                            .allowsHitTesting(false)
                    }
                }
                .frame(width: cardWidth, height: cardHeight)
                .scaleEffect(calculateScale(for: index))
                .offset(y: calculateOffset(for: index))
                .opacity(index == 0 ? 1.0 : 0.5 - Double(index - 1) * 0.15)
                .zIndex(Double(stackCards.count - index))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentCard.id)
    }

    private func calculateScale(for index: Int) -> CGFloat {
        if index == 0 {
            return 1.0
        } else if index == 1 {
            // 進行度に応じて0.95から1.0に拡大
            return 0.95 + swipeProgress * 0.05
        } else {
            // index 2以降も進行度に応じて拡大
            return 1.0 - CGFloat(index) * 0.05 + swipeProgress * 0.05
        }
    }

    private func calculateOffset(for index: Int) -> CGFloat {
        if index == 0 {
            return 0
        } else if index == 1 {
            // 進行度に応じて10から0に移動
            return CGFloat(index) * 10 - swipeProgress * 10
        } else {
            // index 2以降も進行度に応じて移動
            return CGFloat(index) * 10 - swipeProgress * 10
        }
    }

    private var micButton: some View {
        Button(action: {}) {
            Image(systemName: "mic.fill")
                .imageScale(.large)
        }
        .buttonStyle(.borderedProminent)
        .tint(speechViewModel.isRecording ? .red : .blue)
        .controlSize(.extraLarge)
        .scaleEffect(speechViewModel.isRecording ? 1.2 : 1.0)
        .animation(.spring(response: 0.3), value: speechViewModel.isRecording)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !speechViewModel.isRecording {
                        Task {
                            await speechViewModel.startRecording()
                        }
                    }
                }
                .onEnded { _ in
                    if speechViewModel.isRecording {
                        speechViewModel.stopRecording()
                    }
                }
        )
        .alert("エラー", isPresented: .constant(speechViewModel.errorMessage != nil)) {
            Button("OK") {
                speechViewModel.errorMessage = nil
            }
            Button("設定を開く") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
        } message: {
            if let errorMessage = speechViewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

#Preview {
    ContentView()
}

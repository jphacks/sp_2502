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
        GeometryReader { geometry in
            ZStack {
                // 背景色（Figmaデザインに合わせて赤色）
                Color(red: 0x92/255.0, green: 0, blue: 0)
                    .ignoresSafeArea()

                // 背景装飾：左上のカード
                decorativeCard
                    .frame(width: 100, height: 140)
                    .rotationEffect(.degrees(-25))
                    .position(x: 60, y: 80)
                    .opacity(0.6)

                // 背景装飾：右下のカード
                decorativeCard
                    .frame(width: 120, height: 160)
                    .rotationEffect(.degrees(15))
                    .position(x: geometry.size.width - 60, y: geometry.size.height - 100)
                    .opacity(0.5)

                if viewModel.isLoading {
                    ProgressView("Loading cards...")
                        .font(.headline)
                        .foregroundColor(.white)
                } else if viewModel.isGeneratingCard {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("カードを生成中...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        Text(errorMessage)
                            .font(.headline)
                            .foregroundColor(.white)
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
                    // カードスタック表示（中央に大きく配置）
                    cardStackView(currentCard: card, screenSize: geometry.size)

                    // 上部右：Deleteボタン
                    VStack {
                        HStack {
                            Spacer()
                            actionButton(
                                icon: "trash",
                                color: .red,
                                action: { viewModel.handleDelete() }
                            )
                            .padding(.top, 60)
                            .padding(.trailing, 30)
                        }
                        Spacer()
                    }

                    // 左下：Undoボタン
                    VStack {
                        Spacer()
                        HStack {
                            actionButton(
                                icon: "arrow.uturn.backward",
                                color: Color(red: 1.0, green: 0.6, blue: 0.4),
                                action: { viewModel.handleUndo() }
                            )
                            .padding(.leading, 30)
                            .padding(.bottom, 120)
                            Spacer()
                        }
                    }

                    // 右下：Likeボタン
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            actionButton(
                                icon: "hand.thumbsup.fill",
                                color: .green,
                                action: { viewModel.handleLike() }
                            )
                            .padding(.trailing, 30)
                            .padding(.bottom, 120)
                        }
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        Text("No more cards")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }

                // マイク入力ボタン（下部中央に配置）
                VStack {
                    Spacer()
                    micButton
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

        // カードサイズをFigmaデザインに合わせて拡大（画面の90%幅、70%高さ）
        let cardWidth = screenSize.width * 0.9
        let cardHeight = screenSize.height * 0.7

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

    // 背景装飾用のカード
    private var decorativeCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.4, green: 0.3, blue: 0.25),
                            Color(red: 0.25, green: 0.2, blue: 0.15)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
        }
    }
}

#Preview {
    ContentView()
}

//
//  ContentView.swift
//  ios
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CardViewModel()
    @StateObject private var speechViewModel = SpeechRecognizerViewModel()

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
                        ZStack {
                            // 後ろのカード（最大2枚）
                            ForEach(Array(viewModel.getUpcomingCards().enumerated()), id: \.element.id) { index, upcomingCard in
                                CardView(card: upcomingCard)
                                    .scaleEffect(1.0 - CGFloat(index + 1) * 0.05)
                                    .offset(y: CGFloat(index + 1) * 10)
                                    .opacity(0.5 - Double(index) * 0.2)
                                    .zIndex(Double(-index - 1))
                                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: card.id)
                            }

                            // 前面のカード（スワイプ可能）
                            SwipeableCardView(card: card) { direction in
                                viewModel.handleSwipe(direction: direction)
                            }
                            .zIndex(1)
                            .transition(.scale(scale: 0.95).combined(with: .opacity))
                            .id(card.id)
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

    private var micButton: some View {
        Button(action: {}) {
            Image(systemName: "mic.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(speechViewModel.isRecording ? Color.red : Color.blue)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                .scaleEffect(speechViewModel.isRecording ? 1.2 : 1.0)
                .animation(.spring(response: 0.3), value: speechViewModel.isRecording)
        }
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

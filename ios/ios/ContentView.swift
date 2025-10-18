//
//  ContentView.swift
//  ios
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CardViewModel()

    var body: some View {
        ZStack {
            Color(red: 0.95, green: 0.95, blue: 0.95)
                .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView("Loading cards...")
                    .font(.headline)
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

                        SwipeableCardView(card: card) { direction in
                            viewModel.handleSwipe(direction: direction)
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
        }
        .task {
            await viewModel.loadCards()
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
}

#Preview {
    ContentView()
}

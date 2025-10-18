//
//  CardViewModel.swift
//  ios
//

import Foundation
import SwiftUI
import Combine

class CardViewModel: ObservableObject {
    @Published var currentCard: Card?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var cards: [Card] = []
    private var swipeHistory: [(card: Card, action: String)] = []
    private let apiService = APIService.shared

    @MainActor  
    func loadCards() async {
        isLoading = true
        errorMessage = nil

        do {
            cards = try await apiService.fetchCards()
            currentCard = cards.first
        } catch {
            errorMessage = "Failed to load cards: \(error.localizedDescription)"
        }

        isLoading = false
    }

    @MainActor
    func handleSwipe(direction: SwipeDirection) {
        guard let card = currentCard else { return }

        let action: String
        switch direction {
        case .up:
            action = "delete"
        case .down:
            action = "skip"
        case .left:
            performUndo()
            return
        case .right:
            action = "like"
        }

        swipeHistory.append((card: card, action: action))

        Task { @MainActor in
            do {
                try await apiService.sendSwipeAction(cardId: card.id, action: action)
            } catch {
                errorMessage = "Failed to send action: \(error.localizedDescription)"
            }
        }

        moveToNextCard()
    }

    @MainActor
    private func performUndo() {
        guard let lastSwipe = swipeHistory.popLast() else { return }

        cards.insert(lastSwipe.card, at: 0)
        currentCard = lastSwipe.card
    }

    @MainActor
    private func moveToNextCard() {
        if let index = cards.firstIndex(where: { $0.id == currentCard?.id }) {
            cards.remove(at: index)
        }

        if cards.isEmpty {
            Task {
                await loadCards()
            }
        } else {
            currentCard = cards.first
        }
    }

    @MainActor
    func handleDelete() {
        handleSwipe(direction: .up)
    }

    @MainActor
    func handleLike() {
        handleSwipe(direction: .right)
    }

    @MainActor
    func handleSkip() {
        handleSwipe(direction: .down)
    }

    @MainActor
    func handleUndo() {
        performUndo()
    }
}

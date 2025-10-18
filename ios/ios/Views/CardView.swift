//
//  CardView.swift
//  ios
//

import SwiftUI

struct CardView: View {
    let card: Card

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.6, green: 0.6, blue: 0.6),
                            Color(red: 0.2, green: 0.2, blue: 0.2)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)

            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.95, green: 0.9, blue: 0.8),
                                Color(red: 0.9, green: 0.85, blue: 0.75)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        AsyncImage(url: URL(string: card.imageURL)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .clipped()
                            case .failure:
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(12)
                    )
                    .padding(16)

                if let title = card.title {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.bottom, 12)
                }
            }
        }
        .frame(width: 280, height: 380)
    }
}

#Preview {
    CardView(card: Card(
        id: "1",
        imageURL: "https://via.placeholder.com/300",
        title: "Sample Card",
        description: nil
    ))
}

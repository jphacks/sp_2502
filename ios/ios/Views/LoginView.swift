import SwiftUI

struct LoginView: View {
    let onLoginTapped: () -> Void

    var body: some View {
        ZStack {
            // Background color
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo image
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 350, height: 300)

                Spacer()
                    .frame(height: 60)

                // Login button
                Button(action: onLoginTapped) {
                    Text("ログイン")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 32)
                        .background(
                            Color(red: 134/255, green: 15/255, blue: 15/255)
                        )
                        .cornerRadius(20)
                }

                Spacer()
            }
        }
    }
}

#Preview {
    LoginView(onLoginTapped: {
        print("Login tapped")
    })
}

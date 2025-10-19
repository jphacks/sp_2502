//
//  CardView.swift
//  ios
//

import SwiftUI
import Auth0

struct AuthView: View {
    @State var user: User?
    @State private var isAuthenticated: Bool = false
    @State private var accessToken: String = ""

    var body: some View {
        Group {
            if isAuthenticated {
                VStack {
                    ContentView()
                    Button("Fetch Notes") {
                        tRPCService.shared.fetchNotes(accessToken: accessToken)
                    }
                    Button("Logout", action: self.logout)
                }
            } else {
                Button("Login", action: self.login)
            }
        }
        .onAppear {
            checkStoredToken()
        }
    }

    func checkStoredToken() {
        if let token = KeychainHelper.shared.getAccessToken() {
            print("Stored token found: \(token.prefix(20))...")
            isAuthenticated = true
            accessToken = token
        }
    }
}

extension AuthView {
    func login() {
        Auth0
            .webAuth()
            .useHTTPS()
            .audience("https://taskne.ma41.net/")
            .scope("openid profile email offline_access")
            .start { result in
                switch result {
                case .success(let credentials):
                    let token = credentials.accessToken
                    KeychainHelper.shared.saveAccessToken(token)
                    isAuthenticated = true
                    accessToken = token
                
                case .failure(let error):
                  print(error)
                }
            }
    }

    func logout() {
        Auth0
            .webAuth()
            .useHTTPS()
            .audience("https://taskne.ma41.net/")
            .clearSession { result in
                switch result {
                case .success:
                    KeychainHelper.shared.deleteAccessToken()
                    isAuthenticated = false
                    accessToken = ""
                    self.user = nil
                case .failure(let error):
                    print("Failed with: \(error)")
                }
            }
    }
}

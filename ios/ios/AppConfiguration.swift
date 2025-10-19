//
//  AppConfiguration.swift
//  ios
//

import Foundation

enum AppMode {
    case test
    case api
}

class AppConfiguration {
    static let shared = AppConfiguration()

    private init() {}

    // モードの切り替え
    // ここを編集してモードを変更してください
    var currentMode: AppMode {
        return .test  // テストモード（ローカル画像を使用）
        // return .api
    }

    var isTestMode: Bool {
        return currentMode == .test
    }

    var isAPIMode: Bool {
        return currentMode == .api
    }
}

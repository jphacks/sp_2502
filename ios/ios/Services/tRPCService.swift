//
//  tRPCService.swift
//  ios
//
//  Created by yoichi kawashima on 2025/10/19.
//
import Foundation

enum tRPCError: Error {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
    case serverError(statusCode: Int)
}

final class tRPCService {
    static let shared = tRPCService()
    private init() {}

    // ベースURL: ローカル開発環境用
    private let baseURL = "http://localhost:3304/api/trpc"
    // 本番環境用（コメントアウト）: "https://sp-2502.vercel.app/api/trpc"

    // 例: モデルは各自で定義
    // struct Note: Decodable { ... }

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: - SuperJSON → plain JSON 変換
    func superJSONToPlainJSONData(_ data: Data, unwrapSingleArray: Bool = true) throws -> Data {
        print("🔄 [tRPC] SuperJSON変換開始 (データサイズ: \(data.count) bytes)")
        let obj = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        let unwrapped = unwrap(any: obj)
        let normalized = unwrapSingleArray ? flattenSingleArrayObject(unwrapped) : unwrapped
        guard JSONSerialization.isValidJSONObject(normalized) else {
            return data
        }
        return try JSONSerialization.data(withJSONObject: normalized, options: [])
    }

    func decodeFromSuperJSON<T: Decodable>(_ type: T.Type, from data: Data, unwrapSingleArray: Bool = true) throws -> T {
        let plain = try superJSONToPlainJSONData(data, unwrapSingleArray: unwrapSingleArray)
        return try decoder.decode(T.self, from: plain)
    }

    // MARK: - 内部ユーティリティ
    private func unwrap(any: Any) -> Any {
        if let arr = any as? [Any] {
            let mapped = arr.map { unwrap(any: $0) }

            if mapped.allSatisfy({ $0 is [Any] }) {
                return mapped.flatMap { $0 as! [Any] }
            }
            return mapped
        }

        if let dict = any as? [String: Any] {
            if
                let result = dict["result"] as? [String: Any],
                let data = result["data"] as? [String: Any],
                let json = data["json"]
            {
                return unwrap(any: json)
            }

            if let json = dict["json"] {
                return unwrap(any: json)
            }

            var out: [String: Any] = [:]
            for (k, v) in dict { out[k] = unwrap(any: v) }
            return out
        }

        return any
    }

    private func flattenSingleArrayObject(_ any: Any) -> Any {
        if let dict = any as? [String: Any], dict.count == 1, let only = dict.values.first as? [Any] {
            return only
        }
        return any
    }

    // MARK: - Task API

    /// 未処理タスク一覧を取得
    /// ※ バックエンド未実装（task.unprocessedList）のため、現在は使用不可
    /// TODO: バックエンド実装後にコメント解除
    /*
    func fetchUnprocessedTasks(order: String = "desc", accessToken: String? = nil) async throws -> [Card] {
        var comp = URLComponents(string: "https://sp-2502.vercel.app/api/trpc/task.unprocessedList")!
        let inputObj: [String: Any] = ["json": ["order": order]]
        let inputData = try JSONSerialization.data(withJSONObject: inputObj)
        comp.queryItems = [URLQueryItem(name: "input", value: String(data: inputData, encoding: .utf8)!)]

        var req = URLRequest(url: comp.url!)
        req.httpMethod = "GET"
        if let token = accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: req)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw tRPCError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw tRPCError.serverError(statusCode: httpResponse.statusCode)
        }

        let plain = try superJSONToPlainJSONData(data, unwrapSingleArray: true)
        let cards = try decoder.decode([Card].self, from: plain)
        return cards
    }
    */

    /// プロジェクト+タスクを作成
    func createProjectAndTask(projectName: String, taskName: String, accessToken: String? = nil) async throws -> Card {
        print("📝 [tRPC] createProjectAndTask開始 - プロジェクト: \(projectName), タスク: \(taskName)")
        var comp = URLComponents(string: "\(baseURL)/task.projectCreate")!
        let inputObj: [String: Any] = [
            "json": [
                "projectName": projectName,
                "taskName": taskName
            ]
        ]
        let inputData = try JSONSerialization.data(withJSONObject: inputObj)
        comp.queryItems = [URLQueryItem(name: "input", value: String(data: inputData, encoding: .utf8)!)]

        var req = URLRequest(url: comp.url!)
        req.httpMethod = "POST"
        if let token = accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        print("🌐 [tRPC] リクエスト送信: \(req.httpMethod ?? "GET") \(comp.url?.absoluteString ?? "")")
        let (data, response) = try await URLSession.shared.data(for: req)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ [tRPC] 無効なレスポンス")
            throw tRPCError.invalidResponse
        }

        print("✅ [tRPC] レスポンス受信: ステータス \(httpResponse.statusCode), データサイズ \(data.count) bytes")
        guard (200...299).contains(httpResponse.statusCode) else {
            print("❌ [tRPC] サーバーエラー: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 [tRPC] エラーレスポンス内容: \(responseString)")
            }
            throw tRPCError.serverError(statusCode: httpResponse.statusCode)
        }

        let plain = try superJSONToPlainJSONData(data, unwrapSingleArray: false)
        let task = try decoder.decode(Card.self, from: plain)
        print("✅ [tRPC] createProjectAndTask完了")
        return task
    }

    /// タスクを削除
    func deleteTask(taskId: String, accessToken: String? = nil) async throws {
        print("🗑️ [tRPC] deleteTask開始 - タスクID: \(taskId)")
        var comp = URLComponents(string: "\(baseURL)/task.delete")!
        let inputObj: [String: Any] = [
            "json": [
                "taskId": taskId
            ]
        ]
        let inputData = try JSONSerialization.data(withJSONObject: inputObj)
        comp.queryItems = [URLQueryItem(name: "input", value: String(data: inputData, encoding: .utf8)!)]

        var req = URLRequest(url: comp.url!)
        req.httpMethod = "POST"
        if let token = accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        print("🌐 [tRPC] リクエスト送信: \(req.httpMethod ?? "GET") \(comp.url?.absoluteString ?? "")")
        let (data, response) = try await URLSession.shared.data(for: req)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ [tRPC] 無効なレスポンス")
            throw tRPCError.invalidResponse
        }

        print("✅ [tRPC] レスポンス受信: ステータス \(httpResponse.statusCode)")
        guard (200...299).contains(httpResponse.statusCode) else {
            print("❌ [tRPC] サーバーエラー: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 [tRPC] エラーレスポンス内容: \(responseString)")
            }
            throw tRPCError.serverError(statusCode: httpResponse.statusCode)
        }
        print("✅ [tRPC] deleteTask完了")
    }

    struct SplitTaskResult: Decodable {
        let firstTaskId: String
        let firstTaskName: String
        let secondTaskId: String
        let secondTaskName: String

        enum CodingKeys: String, CodingKey {
            case firstTaskId = "first_task_id"
            case firstTaskName = "first_task_name"
            case secondTaskId = "second_task_id"
            case secondTaskName = "second_task_name"
        }
    }

    /// AIでタスクを分割
    func splitTask(taskId: String, accessToken: String? = nil) async throws -> SplitTaskResult {
        print("✂️ [tRPC] splitTask開始 - タスクID: \(taskId)")
        var comp = URLComponents(string: "\(baseURL)/ai.splitTask")!
        let inputObj: [String: Any] = [
            "json": [
                "task_id": taskId
            ]
        ]
        let inputData = try JSONSerialization.data(withJSONObject: inputObj)
        comp.queryItems = [URLQueryItem(name: "input", value: String(data: inputData, encoding: .utf8)!)]

        var req = URLRequest(url: comp.url!)
        req.httpMethod = "POST"
        if let token = accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        print("🌐 [tRPC] リクエスト送信: \(req.httpMethod ?? "GET") \(comp.url?.absoluteString ?? "")")
        let (data, response) = try await URLSession.shared.data(for: req)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ [tRPC] 無効なレスポンス")
            throw tRPCError.invalidResponse
        }

        print("✅ [tRPC] レスポンス受信: ステータス \(httpResponse.statusCode), データサイズ \(data.count) bytes")
        guard (200...299).contains(httpResponse.statusCode) else {
            print("❌ [tRPC] サーバーエラー: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 [tRPC] エラーレスポンス内容: \(responseString)")
            }
            throw tRPCError.serverError(statusCode: httpResponse.statusCode)
        }

        let plain = try superJSONToPlainJSONData(data, unwrapSingleArray: false)
        let result = try decoder.decode(SplitTaskResult.self, from: plain)
        print("✅ [tRPC] splitTask完了 - 第1タスク: \(result.firstTaskName), 第2タスク: \(result.secondTaskName)")
        return result
    }
}

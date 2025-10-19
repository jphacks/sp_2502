//
//  tRPCService.swift
//  ios
//
//  Created by yoichi kawashima on 2025/10/19.
//
import Foundation

final class tRPCService {
    static let shared = tRPCService()
    private init() {}

    // 例: モデルは各自で定義
    // struct Note: Decodable { ... }

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: - SuperJSON → plain JSON 変換
    func superJSONToPlainJSONData(_ data: Data, unwrapSingleArray: Bool = true) throws -> Data {
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

    // MARK: - fetch使用例
    struct Note: Decodable {
        let id: String
        let userId: String
        let title: String
        let content: String?
        let createdAt: Date
        let updatedAt: Date
    }

    func fetchNotes(accessToken: String) {
        var comp = URLComponents(string: "https://sp-2502.vercel.app/api/trpc/note.list")!
        let inputObj: [String: Any] = ["json": [:]]
        let inputData = try! JSONSerialization.data(withJSONObject: inputObj)
        comp.queryItems = [URLQueryItem(name: "input", value: String(data: inputData, encoding: .utf8)! )]

        var req = URLRequest(url: comp.url!)
        req.httpMethod = "GET"
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: req) { data, _, err in
            if let err = err { print("network error:", err); return }
            guard let data = data else { print("no data"); return }

            // 1) plain JSON Data を取得（notes配列にフラット化）
            do {
                let plain = try self.superJSONToPlainJSONData(data, unwrapSingleArray: true)
                if let raw = String(data: plain, encoding: .utf8) { print("plain:", raw) }

                // 2) あとは任意の型で普通にデコード
                let notes = try self.decoder.decode([Note].self, from: plain)
                // 例
                print(notes[0].id)
            } catch {
                print("transform failed:", error)
            }
        }.resume()
    }
}

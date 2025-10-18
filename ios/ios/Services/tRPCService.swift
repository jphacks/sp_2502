//
//  tRPCService.swift
//  ios
//
//  Created by yoichi kawashima on 2025/10/19.
//

import Foundation

final class tRPCService {
    static let shared = tRPCService()
    private let baseURL = "http://localhost:3304/" // デプロイ後は https://sp-2502.vercel.app/

    private init() {}
    
    func fetchNotes(accessToken: String) {
        var comp = URLComponents(string: "http://localhost:3304/api/trpc/note.list")!
        // 送る実体
        let payload: [String: Any] = [:] // 例: ["limit": 50, "offset": 0]
        let inputObj: [String: Any] = ["json": payload]
        let inputData = try! JSONSerialization.data(withJSONObject: inputObj)
        let inputStr = String(data: inputData, encoding: .utf8)!
        comp.queryItems = [URLQueryItem(name: "input", value: inputStr)]

        var req = URLRequest(url: comp.url!)
        req.httpMethod = "GET"
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: req) { data, resp, err in
            if let err = err { print("network error:", err); return }
            guard let data = data else { print("no data"); return }
            
            // 1) 生JSONを確認
            if let raw = String(data: data, encoding: .utf8) {
                print("raw:", raw)
            }
        }.resume()
    }
}

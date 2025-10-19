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
    private let baseURL = "http://localhost:3304"
    // 本番環境用（コメントアウト）: "https://sp-2502.vercel.app/api/trpc"
    
    static let shared = tRPCService()
    
    private let client: TRPCClient
    private init() {
        client = TRPCClient(baseURL: URL(string: baseURL)!, basePath: "api/trpc")
}

    // [GET] /note.list
    func fetchList(token: String) async {
        do {
            let list = try await client.get(
                endpoint: "note.list",
                data: .obj([:]),
                headers: ["Authorization": "Bearer \(token)"]
            )
            
            guard let notes = list["notes"]?.array else {
                // notesキーがない or 型が配列でない
                return
            }

            for note in notes {
                let id      = note["id"]?.asString() ?? ""
                let title   = note["title"]?.asString() ?? ""
                let content = note["content"]?.asString() ?? ""
                
                print(id, title, content)
            }
        } catch {
            print("リクエストに失敗")
            print(error.localizedDescription)
        }
    }
    
    func postNote(token: String) async {
        do {
            let note = try await client.post(
                endpoint: "note.create",
                data: .obj([
                    "title": .s("Swift x tRPC"),
                    "content": .s("48時間で作る Swift x tRPCの通信")
                ]),
                headers: ["Authorization": "Bearer \(token)"]
            )
            print("リクエストに成功")
            print(note)
        } catch {
            print("リクエストに失敗")
            print(error.localizedDescription)
        }
    }
}

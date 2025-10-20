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
    private let baseURL = "https://sp-2502.vercel.app"
    // 本番環境用（コメントアウト）: "https://sp-2502.vercel.app"

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

    func deleteTask(taskId: String, token: String) async {
        do {
            _ = try await client.post(
                endpoint: "task.delete",
                data: .obj(["taskId": .s(taskId)]),
                headers: ["Authorization": "Bearer \(token)"]
            )
        } catch {
            print("❌タスクデータの削除に失敗")
            print(error.localizedDescription)
        }
    }

    func statusUpdateTask(taskId: String, status: TaskStatus, token: String) async {
        do {
            _ = try await client.post(
                endpoint: "task.statusUpdate",
                data: .obj([
                    "taskId": .s(taskId),
                    "status": .s(status.rawValue)
                ]),
                headers: ["Authorization": "Bearer \(token)"]
            )
        } catch {
            print("❌タスクステータスの更新に失敗")
            print(error.localizedDescription)
        }
    }
    
    func splitTaskAI(taskId: String, token: String) async -> [Card] {
        do {
            let tasks = try await client.post(
                endpoint: "ai.splitTask",
                data: .obj([
                    "taskId": .s(taskId)
                ]),
                headers: ["Authorization": "Bearer \(token)"]
            )
            
            print("リクエスト成功")
            print(tasks)

            let card1: Card = Card(
                id: tasks.at("first_task_id")?.asString() ?? "",
                imageURL: "",
                title: tasks.at("first_task_name")?.asString() ?? "",
                description: ""
            )
            
            let card2: Card = Card(
                id: tasks.at("second_task_id")?.asString() ?? "",
                imageURL: "",
                title: tasks.at("second_task_name")?.asString() ?? "",
                description: ""
            )
            
            return [card1, card2]
        } catch {
            print("❌タスク分割AIの呼び出しに失敗")
            print(error.localizedDescription)
            return []
        }
    }
    
    func projectCreateTask(projectName: String, TaskName: String, token: String) async -> Card? {
        do {
            let result = try await client.post(
                endpoint: "task.projectCreate",
                data: .obj([
                    "projectName": .s(projectName),
                    "taskName": .s(TaskName)
                ]),
                headers: ["Authorization": "Bearer \(token)"]
            )

            // TaskDTOをCardに変換
            let id = result.at("id")?.asString() ?? ""
            let name = result.at("name")?.asString() ?? ""
            let userId = result.at("userId")?.asString()
            let projectId = result.at("projectId")?.asString()
            let statusStr = result.at("status")?.asString() ?? "unprocessed"
            let status = TaskStatus(rawValue: statusStr) ?? .unprocessed
            let priority = result.at("priority")?.asString()
            let parentId = result.at("parentId")?.asString()

            // 日付の処理
            var createdAt: Date?
            var updatedAt: Date?
            var date: Date?

            if let createdAtStr = result.at("createdAt")?.asString() {
                createdAt = ISO8601DateFormatter().date(from: createdAtStr)
            }
            if let updatedAtStr = result.at("updatedAt")?.asString() {
                updatedAt = ISO8601DateFormatter().date(from: updatedAtStr)
            }
            if let dateStr = result.at("date")?.asString() {
                date = ISO8601DateFormatter().date(from: dateStr)
            }

            let card = Card(
                id: id,
                imageURL: "", // 画像は後で生成
                title: name,
                description: nil,
                isLocalImage: false,
                userId: userId,
                projectId: projectId,
                name: name,
                date: date,
                status: status,
                priority: priority,
                parentId: parentId,
                createdAt: createdAt,
                updatedAt: updatedAt
            )

            return card
        } catch {
            print("❌プロジェクト作成とタスク追加に失敗")
            print(error.localizedDescription)
            return nil
        }
    }

    func fetchActiveTasks(token: String) async -> [Card] {
        do {
            let result = try await client.get(
                endpoint: "task.activeList",
                data: .obj(["order": .s("desc")]),
                headers: ["Authorization": "Bearer \(token)"]
            )
            
            print("✅アクティブタスクの取得に成功")
            print(result)

            guard let tasks = result.at("tasks")?.array else {
                print("❌タスクリストの取得に失敗: tasks配列がありません")
                return []
            }
            
            print("取得したタスク数: \(tasks.count)")

            var cards: [Card] = []
            for task in tasks {
                let id = task.at("id")?.asString() ?? ""
                let name = task.at("name")?.asString() ?? ""
                let userId = task.at("userId")?.asString()
                let projectId = task.at("projectId")?.asString()
                let statusStr = task.at("status")?.asString() ?? "unprocessed"
                let status = TaskStatus(rawValue: statusStr) ?? .unprocessed
                let priority = task.at("priority")?.asString()
                let parentId = task.at("parentId")?.asString()

                // 日付の処理（SuperJSONの日付フォーマットに対応）
                var createdAt: Date?
                var updatedAt: Date?
                var date: Date?

                if let createdAtStr = task.at("createdAt")?.asString() {
                    createdAt = ISO8601DateFormatter().date(from: createdAtStr)
                }
                if let updatedAtStr = task.at("updatedAt")?.asString() {
                    updatedAt = ISO8601DateFormatter().date(from: updatedAtStr)
                }
                if let dateStr = task.at("date")?.asString() {
                    date = ISO8601DateFormatter().date(from: dateStr)
                }

                let card = Card(
                    id: id,
                    imageURL: "",
                    title: name,
                    description: nil,
                    isLocalImage: false,
                    userId: userId,
                    projectId: projectId,
                    name: name,
                    date: date,
                    status: status,
                    priority: priority,
                    parentId: parentId,
                    createdAt: createdAt,
                    updatedAt: updatedAt
                )
                cards.append(card)
            }

            return cards
        } catch {
            print("❌アクティブタスクの取得に失敗")
            print(error.localizedDescription)
            return []
        }
    }
}

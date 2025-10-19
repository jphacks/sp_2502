import Foundation

// 最小値型（文字列・数値中心）
public enum TRPCValue {
    case string(String)
    case number(Double)
    case array([TRPCValue])
    case object([String: TRPCValue])
    case null

    public static func s(_ v: String) -> TRPCValue { .string(v) }
    public static func n<T: BinaryInteger>(_ v: T) -> TRPCValue { .number(Double(v)) }
    public static func f(_ v: Double) -> TRPCValue { .number(v) }
    public static func obj(_ v: [String: TRPCValue]) -> TRPCValue { .object(v) }
    public static func arr(_ v: [TRPCValue]) -> TRPCValue { .array(v) }
}

public struct TRPCClient {
    public let baseURL: URL
    public let basePath: String
    public var defaultHeaders: [String: String] = [:]
    private let session: URLSession = .shared

    public init(baseURL: URL, basePath: String = "api/trpc", defaultHeaders: [String: String] = [:]) {
        self.baseURL = baseURL
        self.basePath = basePath
        self.defaultHeaders = defaultHeaders
    }

    // 単発 GET
    public func get(
        endpoint: String,
        data: TRPCValue? = nil,
        headers: [String: String] = [:]
    ) async throws -> TRPCValue {
        try await request(method: "GET", endpoint: endpoint, data: data, batch: false, id: 0, headers: headers)
    }

    // 単発 POST
    public func post(
        endpoint: String,
        data: TRPCValue? = nil,
        headers: [String: String] = [:]
    ) async throws -> TRPCValue {
        try await request(method: "POST", endpoint: endpoint, data: data, batch: false, id: 0, headers: headers)
    }

    // バッチ GET（id は任意。複数回呼ぶ想定なら呼び出し側で管理）
    public func getBatch(
        endpoint: String,
        data: TRPCValue? = nil,
        id: Int = 0,
        headers: [String: String] = [:]
    ) async throws -> TRPCValue {
        try await request(method: "GET", endpoint: endpoint, data: data, batch: true, id: id, headers: headers)
    }

    // バッチ POST
    public func postBatch(
        endpoint: String,
        data: TRPCValue? = nil,
        id: Int = 0,
        headers: [String: String] = [:]
    ) async throws -> TRPCValue {
        try await request(method: "POST", endpoint: endpoint, data: data, batch: true, id: id, headers: headers)
    }

    // MARK: - Core
    private func request(
        method: String,
        endpoint: String,
        data: TRPCValue?,
        batch: Bool,
        id: Int,
        headers: [String: String]
    ) async throws -> TRPCValue {

        var url = baseURL
            .appendingPathComponent(basePath)
            .appendingPathComponent(endpoint)

        var req: URLRequest

        if method == "GET" {
            var comp = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            var items = comp.queryItems ?? []
            if batch {
                items.append(.init(name: "batch", value: "1"))
                items.append(.init(name: "input", value: try makeInputJSONString(data, batch: true, id: id)))
            } else {
                items.append(.init(name: "input", value: try makeInputJSONString(data, batch: false, id: id)))
            }
            comp.queryItems = items
            url = comp.url!
            req = URLRequest(url: url)
        } else {
            // POST
            if batch {
                // /.../endpoint?batch=1 で本文に {"<id>":{"json":...}}
                var comp = URLComponents(url: url, resolvingAgainstBaseURL: false)!
                var items = comp.queryItems ?? []
                items.append(.init(name: "batch", value: "1"))
                comp.queryItems = items
                url = comp.url!
                req = URLRequest(url: url)
                req.httpBody = try makePOSTBody(data, batch: true, id: id)
            } else {
                // 単発: {"id":<id>,"json":...}
                req = URLRequest(url: url)
                req.httpBody = try makePOSTBody(data, batch: false, id: id)
            }
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        (defaultHeaders.merging(headers, uniquingKeysWith: { _, new in new })).forEach {
            req.setValue($0.value, forHTTPHeaderField: $0.key)
        }

        let (respData, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw TRPCError.transport }
        guard (200..<300).contains(http.statusCode) else {
            let msg = String(data: respData, encoding: .utf8) ?? ""
            throw TRPCError.httpStatus(code: http.statusCode, body: msg)
        }
        return try decodeTRPCPayload(respData)
    }

    // MARK: - Encode (SuperJSON input)
    private func makeInputJSONString(_ v: TRPCValue?, batch: Bool, id: Int) throws -> String {
        let payload = toAnyOrEmpty(v) // {} をデフォルト
        let obj: Any
        if batch {
            obj = [String(id): ["json": payload]]
        } else {
            obj = ["json": payload]
        }
        let data = try JSONSerialization.data(withJSONObject: obj, options: [])
        return String(data: data, encoding: .utf8)!
    }

    private func makePOSTBody(_ v: TRPCValue?, batch: Bool, id: Int) throws -> Data {
        let payload = toAnyOrEmpty(v)
        let body: Any
        if batch {
            body = [String(id): ["json": payload]]
        } else {
            body = ["id": id, "json": payload]
        }
        return try JSONSerialization.data(withJSONObject: body, options: [])
    }

    private func toAnyOrEmpty(_ v: TRPCValue?) -> Any {
        // nil は {} に補正（= 空オブジェクト）
        guard let v else { return [String: Any]() }
        return toAny(v)
    }

    private func toAny(_ v: TRPCValue) -> Any {
        switch v {
        case .string(let s): return s
        case .number(let d): return d
        case .array(let arr): return arr.map { toAny($0) }
        case .object(let dict): return dict.mapValues { toAny($0) }
        case .null: return NSNull()
        }
    }

    // MARK: - Decode (tRPC + SuperJSON)
    private func decodeTRPCPayload(_ data: Data) throws -> TRPCValue {
        let raw = try JSONSerialization.jsonObject(with: data, options: [])

        // 単発: { "result": { "data": <superjson> } } or { "error": ... }
        if let dict = raw as? [String: Any] {
            if let err = dict["error"] as? [String: Any] {
                let msg = (err["message"] as? String) ?? "tRPC error"
                throw TRPCError.rpc(message: msg, raw: err)
            }
            if let result = dict["result"] as? [String: Any] {
                return unwrapResult(result)
            }
            // 稀に {"json":...} を直返しする実装もある
            if dict["json"] != nil { return unwrapSuperJSON(dict) }

            // 返りが id マップの形 {"0": {"result": {...}}, ...}
            if dict.keys.allSatisfy({ Int($0) != nil }) {
                var out: [String: TRPCValue] = [:]
                for (k, v) in dict {
                    if let r = (v as? [String: Any])?["result"] as? [String: Any] {
                        out[k] = unwrapResult(r)
                    } else {
                        out[k] = fromAny(v)
                    }
                }
                return .object(out)
            }
        }

        // バッチ標準: [ { "id":0, "result": { "type":"data", "data": <superjson> } }, ... ]
        if let arr = raw as? [Any] {
            let values: [TRPCValue] = arr.map { elem in
                if let e = elem as? [String: Any],
                   let r = e["result"] as? [String: Any] {
                    return unwrapResult(r)
                } else {
                    return fromAny(elem)
                }
            }
            return .array(values)
        }

        return fromAny(raw)
    }

    private func unwrapResult(_ result: [String: Any]) -> TRPCValue {
        // "data" 優先。SuperJSON の {json, meta} をアンラップ
        if let data = result["data"] {
            return unwrapSuperJSON(data)
        }
        return fromAny(result)
    }

    private func unwrapSuperJSON(_ any: Any) -> TRPCValue {
        // { "json": <value>, "meta": ... } -> <value>
        if let dict = any as? [String: Any], let j = dict["json"] {
            return fromAny(j)
        }
        return fromAny(any)
    }

    private func fromAny(_ any: Any) -> TRPCValue {
        switch any {
        case let s as String: return .string(s)
        case let n as NSNumber: return .number(n.doubleValue)
        case let arr as [Any]: return .array(arr.map(fromAny))
        case let dict as [String: Any]:
            var out: [String: TRPCValue] = [:]
            for (k, v) in dict { out[k] = fromAny(v) }
            return .object(out)
        default: return .null
        }
    }
}

// MARK: - Errors
public enum TRPCError: Error, LocalizedError {
    case transport
    case httpStatus(code: Int, body: String)
    case rpc(message: String, raw: [String: Any])

    public var errorDescription: String? {
        switch self {
        case .transport: return "transport error"
        case .httpStatus(let c, let b): return "http \(c): \(b)"
        case .rpc(let m, _): return m
        }
    }
}

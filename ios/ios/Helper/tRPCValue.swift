//
//  tRPCValue.swift
//  ios
//
import Foundation

extension TRPCValue {
    // 型別アンラップ
    var string: String? {
        if case .string(let s) = self { return s }; return nil
    }
    var number: Double? {
        if case .number(let d) = self { return d }; return nil
    }
    var int: Int? { number.map { Int($0) } }
    var array: [TRPCValue]? {
        if case .array(let a) = self { return a }; return nil
    }
    var object: [String: TRPCValue]? {
        if case .object(let o) = self { return o }; return nil
    }

    // 辞書/配列アクセス
    subscript(_ key: String) -> TRPCValue? { object?[key] }
    subscript(_ index: Int) -> TRPCValue? {
        guard let a = array, a.indices.contains(index) else { return nil }
        return a[index]
    }

    // ドット区切りパス ("items.0.title" など)
    func at(_ path: String) -> TRPCValue? {
        let parts = path.split(separator: ".").map(String.init)
        return parts.reduce(self as TRPCValue?) { acc, p in
            guard let cur = acc else { return nil }
            if let i = Int(p) { return cur[i] }
            return cur[p]
        }
    }

    // デフォルト付きの簡易取り出し
    func asString(_ defaultValue: String = "") -> String {
        string ?? (number.map { String($0) } ?? defaultValue)
    }
    func asNumber(_ defaultValue: Double = 0) -> Double {
        number ?? (string.flatMap { Double($0) } ?? defaultValue)
    }
}

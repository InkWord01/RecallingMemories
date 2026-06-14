//
//  MemorySearch.swift
//  拾忆
//
//  纯逻辑搜索引擎 — 跨文本/人物/地点/标签/情绪的统一筛选 + 评分排序
//

import Foundation

/// 搜索筛选条件 — 多维组合
struct MemorySearchQuery: Equatable {
    /// 关键词（支持空格分词，全部命中才算匹配）
    var keyword: String = ""
    /// 必须包含这些人物（id）
    var personIDs: Set<UUID> = []
    /// 必须命中的情绪标签
    var moodTag: String?
    /// 必须命中的地点（POI 全名精确匹配）
    var locationName: String?
    /// 必须含有附件
    var requireAttachments: Bool = false
    /// 时间范围（闭区间，nil 表示不约束）
    var dateRange: ClosedRange<Date>?

    var isEmpty: Bool {
        keyword.isEmpty && personIDs.isEmpty && moodTag == nil
            && locationName == nil && !requireAttachments && dateRange == nil
    }
}

enum MemorySearch {

    /// 根据查询过滤记忆，命中度高的排前面（同分按时间倒序）
    static func filter(_ memories: [Memory], by query: MemorySearchQuery) -> [Memory] {
        guard !query.isEmpty else { return memories }

        let tokens = tokenize(query.keyword)

        return memories
            .compactMap { memory -> (Memory, Int)? in
                guard matches(memory, query: query, tokens: tokens) else { return nil }
                return (memory, score(memory, tokens: tokens))
            }
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
                return lhs.0.createdAt > rhs.0.createdAt
            }
            .map(\.0)
    }

    // MARK: - 命中判定

    private static func matches(_ memory: Memory,
                                query: MemorySearchQuery,
                                tokens: [String]) -> Bool {
        // 关键词：所有 token 都必须命中至少一个字段
        if !tokens.isEmpty {
            let haystack = makeHaystack(memory)
            for token in tokens {
                if !haystack.localizedCaseInsensitiveContains(token) { return false }
            }
        }

        if !query.personIDs.isEmpty {
            let memoryPeople = Set(memory.people.map(\.id))
            // 「全部命中」语义：所有筛选的人都需在场（更直觉，避免噪声）
            if !query.personIDs.isSubset(of: memoryPeople) { return false }
        }

        if let mood = query.moodTag, memory.moodTag != mood { return false }
        if let location = query.locationName, memory.locationName != location { return false }
        if query.requireAttachments, memory.attachments.isEmpty { return false }
        if let range = query.dateRange, !range.contains(memory.createdAt) { return false }

        return true
    }

    /// 把一条记忆压成可搜索的全文字段
    private static func makeHaystack(_ memory: Memory) -> String {
        var parts: [String] = [memory.text]
        if let location = memory.locationName { parts.append(location) }
        if let mood = memory.moodTag { parts.append(mood) }
        parts.append(contentsOf: memory.tags)
        parts.append(contentsOf: memory.people.map(\.name))
        return parts.joined(separator: " ")
    }

    // MARK: - 评分（命中字段越「重要」分越高）

    private static func score(_ memory: Memory, tokens: [String]) -> Int {
        guard !tokens.isEmpty else { return 0 }
        var score = 0
        for token in tokens {
            if memory.text.localizedCaseInsensitiveContains(token)        { score += 5 }
            if memory.locationName?.localizedCaseInsensitiveContains(token) == true { score += 3 }
            if memory.tags.contains(where: { $0.localizedCaseInsensitiveContains(token) }) { score += 4 }
            if memory.people.contains(where: { $0.name.localizedCaseInsensitiveContains(token) }) { score += 4 }
            if memory.moodTag?.localizedCaseInsensitiveContains(token) == true { score += 2 }
        }
        return score
    }

    // MARK: - 工具

    private static func tokenize(_ keyword: String) -> [String] {
        keyword
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
            .filter { !$0.isEmpty }
    }
}

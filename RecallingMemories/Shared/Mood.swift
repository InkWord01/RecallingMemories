//
//  Mood.swift
//  拾忆
//
//  情绪标签 — 中央化，方便 VoiceOver 把 emoji 转成中文 / 后续做主题色
//

import Foundation

enum Mood {
    /// 把「💡顿悟」拆出中文部分，给 VoiceOver 一个干净的中文标签
    /// 失败回退到原串（VoiceOver 自己念 emoji + 中文）
    static func accessibilityLabel(for tag: String) -> String {
        // 过滤掉所有 emoji / 符号 scalar，保留汉字
        let chinese = tag.unicodeScalars
            .filter { scalar in
                !scalar.properties.isEmojiPresentation
                    && !scalar.properties.isEmoji
            }
            .map(String.init)
            .joined()
            .trimmingCharacters(in: .whitespaces)
        return chinese.isEmpty ? tag : "情绪：\(chinese)"
    }
}

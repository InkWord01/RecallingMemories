//
//  ContactsService.swift
//  拾忆
//
//  系统通讯录访问 — 读取联系人用于「和谁在一起」标签
//

import Foundation
import Contacts

@MainActor
final class ContactsService {
    static let shared = ContactsService()

    private let store = CNContactStore()

    /// 请求通讯录权限
    func requestAccess() async -> Bool {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return (try? await store.requestAccess(for: .contacts)) ?? false
        default:
            return false
        }
    }

    /// 拉取所有联系人（仅姓名 + 头像 + 标识符）
    func fetchAll() async throws -> [ContactItem] {
        let granted = await requestAccess()
        guard granted else {
            throw NSError(domain: "ContactsService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "未授权通讯录访问"])
        }

        let keys: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactNicknameKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor,
        ]
        let request = CNContactFetchRequest(keysToFetch: keys)
        request.sortOrder = .userDefault

        var items: [ContactItem] = []
        try store.enumerateContacts(with: request) { contact, _ in
            let name = [contact.familyName, contact.givenName]
                .filter { !$0.isEmpty }
                .joined()
            let display = !contact.nickname.isEmpty ? contact.nickname
                : (name.isEmpty ? "未命名" : name)
            items.append(ContactItem(
                identifier: contact.identifier,
                displayName: display,
                thumbnailData: contact.thumbnailImageData
            ))
        }
        return items
    }
}

/// UI 层使用的轻量联系人项
struct ContactItem: Identifiable, Hashable {
    var id: String { identifier }
    let identifier: String
    let displayName: String
    let thumbnailData: Data?
}

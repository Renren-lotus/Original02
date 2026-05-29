//
//  GroupRealtimeSyncService.swift
//  Original02
//
//  Created by Codex on 2026/05/29.
//

import CloudKit
import Foundation

/// CloudKitに保存する1人分1日分の食事データです。
struct GroupMealEntry {
    var groupId: String
    var dayKey: String
    var date: Date
    var memberId: String
    var memberName: String
    var breakfast: MealStatus
    var lunch: MealStatus
    var dinner: MealStatus
    var note: String
}

/// グループの予定をCloudKitと同期するサービスです。
final class GroupRealtimeSyncService {
    private let database: CKDatabase?
    private let recordType = "MealPlanEntry"

    init(container: CKContainer? = nil) {
        if AppRuntime.isPreview {
            database = nil
        } else {
            let resolvedContainer = container ?? CKContainer.default()
            database = resolvedContainer.publicCloudDatabase
        }
    }

    /// 指定グループと対象日の予定を取得します。
    func fetchEntries(groupId: String, dayKeys: [String]) async throws -> [GroupMealEntry] {
        guard !groupId.isEmpty else { return [] }
        guard !dayKeys.isEmpty else { return [] }
        guard let database else { return [] }

        let query = CKQuery(
            recordType: recordType,
            predicate: NSPredicate(format: "groupId == %@ AND dayKey IN %@", groupId, dayKeys)
        )
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]

        let (results, _) = try await database.records(
            matching: query,
            inZoneWith: nil,
            desiredKeys: nil,
            resultsLimit: 400
        )

        return results.compactMap { _, result in
            guard case let .success(record) = result else { return nil }
            return Self.entry(from: record)
        }
    }

    /// 指定データをCloudKitへ保存します。
    func upsert(entry: GroupMealEntry) async throws {
        guard let database else { return }
        let recordId = CKRecord.ID(recordName: Self.recordName(groupId: entry.groupId, dayKey: entry.dayKey, memberId: entry.memberId))
        let record = CKRecord(recordType: recordType, recordID: recordId)
        record["groupId"] = entry.groupId as CKRecordValue
        record["dayKey"] = entry.dayKey as CKRecordValue
        record["date"] = entry.date as CKRecordValue
        record["memberId"] = entry.memberId as CKRecordValue
        record["memberName"] = entry.memberName as CKRecordValue
        record["breakfast"] = entry.breakfast.rawValue as CKRecordValue
        record["lunch"] = entry.lunch.rawValue as CKRecordValue
        record["dinner"] = entry.dinner.rawValue as CKRecordValue
        record["note"] = entry.note as CKRecordValue
        _ = try await database.save(record)
    }

    /// Recordをアプリ内モデルへ変換します。
    private static func entry(from record: CKRecord) -> GroupMealEntry? {
        guard
            let groupId = record["groupId"] as? String,
            let dayKey = record["dayKey"] as? String,
            let date = record["date"] as? Date,
            let memberId = record["memberId"] as? String,
            let memberName = record["memberName"] as? String,
            let breakfastRaw = record["breakfast"] as? Int,
            let lunchRaw = record["lunch"] as? Int,
            let dinnerRaw = record["dinner"] as? Int,
            let breakfast = MealStatus(rawValue: breakfastRaw),
            let lunch = MealStatus(rawValue: lunchRaw),
            let dinner = MealStatus(rawValue: dinnerRaw)
        else {
            return nil
        }

        let note = record["note"] as? String ?? ""
        return GroupMealEntry(
            groupId: groupId,
            dayKey: dayKey,
            date: date,
            memberId: memberId,
            memberName: memberName,
            breakfast: breakfast,
            lunch: lunch,
            dinner: dinner,
            note: note
        )
    }

    /// 1レコードに対する一意な名前を作成します。
    private static func recordName(groupId: String, dayKey: String, memberId: String) -> String {
        let raw = "\(groupId)_\(dayKey)_\(memberId)"
        return raw.replacingOccurrences(of: "[^a-zA-Z0-9_-]", with: "_", options: .regularExpression)
    }
}

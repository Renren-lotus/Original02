//
//  MealPlannerViewModel.swift
//  Original02
//
//  Created by Codex on 2026/05/27.
//

import Foundation
import Observation
import SwiftData

/// 上部タブのページ種類です。
enum HomePage: Int, CaseIterable, Identifiable {
    case today
    case week

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .today:
            return "今日"
        case .week:
            return "今週"
        }
    }
}

/// グループ内の表示用メンバー情報です。
struct GroupMember: Identifiable, Hashable {
    var id: String
    var name: String
    var isCurrentUser: Bool
}

/// 食事予定画面全体の状態と処理を管理します。
@Observable
final class MealPlannerViewModel {
    var selectedPage: HomePage = .today
    var showingEditor = false
    var showingGroupSettings = false
    var editingDate = Date()

    /// 編集モーダルを開きます。
    func openEditor(for date: Date, canEdit: Bool) {
        guard canEdit else { return }
        editingDate = date
        showingEditor = true
    }

    /// 編集モーダルを閉じます。
    func closeEditor() {
        showingEditor = false
    }

    /// グループ設定モーダルを開きます。
    func openGroupSettings() {
        showingGroupSettings = true
    }

    /// グループ設定モーダルを閉じます。
    func closeGroupSettings() {
        showingGroupSettings = false
    }

    /// 指定日付のデータを一覧から取得します。
    func plan(for date: Date, groupId: String, in plans: [DayPlan]) -> DayPlan? {
        let key = DayPlan.groupDayKey(groupId: groupId, date: date)
        return plans.first(where: { $0.groupDayKey == key })
    }

    /// 指定グループの日次データを必ず返し、無ければ初期作成します。
    func ensurePlan(
        for date: Date,
        groupId: String,
        currentUserId: String,
        currentUserName: String,
        in plans: [DayPlan],
        context: ModelContext
    ) -> DayPlan {
        if let existing = plan(for: date, groupId: groupId, in: plans) {
            return existing
        }

        let newPlan = DayPlan(
            date: date,
            groupId: groupId,
            memberPlans: [
                MemberMealPlan(memberId: currentUserId, name: currentUserName)
            ]
        )
        context.insert(newPlan)
        return newPlan
    }

    /// グループ内の表示メンバー一覧を返します。
    func members(groupId: String, currentUserId: String, currentUserName: String, plans: [DayPlan]) -> [GroupMember] {
        var map: [String: String] = [currentUserId: currentUserName]

        let groupedPlans = plans.filter { $0.groupId == groupId }
        for dayPlan in groupedPlans {
            for memberPlan in dayPlan.memberPlans {
                map[memberPlan.memberId] = memberPlan.name
            }
        }

        return map
            .map { key, value in
                GroupMember(id: key, name: value, isCurrentUser: key == currentUserId)
            }
            .sorted {
                if $0.isCurrentUser != $1.isCurrentUser {
                    return $0.isCurrentUser
                }
                return $0.name.localizedCompare($1.name) == .orderedAscending
            }
    }

    /// メンバーの編集可否を判定します。
    func canEdit(memberId: String, currentUserId: String) -> Bool {
        memberId == currentUserId
    }

    /// 家族1人分の食事状態を順番に切り替えます。
    func cycleStatus(
        for memberId: String,
        mealTime: MealTime,
        date: Date,
        groupId: String,
        currentUserId: String,
        currentUserName: String,
        plans: [DayPlan],
        context: ModelContext
    ) {
        guard canEdit(memberId: memberId, currentUserId: currentUserId) else { return }

        let targetPlan = ensurePlan(
            for: date,
            groupId: groupId,
            currentUserId: currentUserId,
            currentUserName: currentUserName,
            in: plans,
            context: context
        )

        if let index = targetPlan.memberPlans.firstIndex(where: { $0.memberId == memberId }) {
            let current = targetPlan.memberPlans[index].status(for: mealTime)
            let next = current.next()
            targetPlan.memberPlans[index].setStatus(next, for: mealTime)
            targetPlan.memberPlans[index].name = currentUserName
        } else {
            var newMember = MemberMealPlan(memberId: currentUserId, name: currentUserName)
            newMember.setStatus(.home, for: mealTime)
            targetPlan.memberPlans.append(newMember)
        }
    }

    /// 編集画面の保存内容を反映します。
    func saveOwnPlan(
        for date: Date,
        groupId: String,
        currentUserId: String,
        currentUserName: String,
        breakfast: MealStatus,
        lunch: MealStatus,
        dinner: MealStatus,
        note: String,
        plans: [DayPlan],
        context: ModelContext
    ) {
        let targetPlan = ensurePlan(
            for: date,
            groupId: groupId,
            currentUserId: currentUserId,
            currentUserName: currentUserName,
            in: plans,
            context: context
        )

        if let index = targetPlan.memberPlans.firstIndex(where: { $0.memberId == currentUserId }) {
            targetPlan.memberPlans[index].breakfast = breakfast
            targetPlan.memberPlans[index].lunch = lunch
            targetPlan.memberPlans[index].dinner = dinner
            targetPlan.memberPlans[index].note = note
            targetPlan.memberPlans[index].name = currentUserName
        } else {
            let newMember = MemberMealPlan(
                memberId: currentUserId,
                name: currentUserName,
                breakfast: breakfast,
                lunch: lunch,
                dinner: dinner,
                note: note
            )
            targetPlan.memberPlans.append(newMember)
        }

        closeEditor()
    }

    /// 指定時間帯で「家で食べる」人数を返します。
    func homeCount(for mealTime: MealTime, in plan: DayPlan?) -> Int {
        guard let plan else { return 0 }
        return plan.memberPlans.filter { $0.status(for: mealTime) == .home }.count
    }

    /// 指定メンバーの食事状態を返します。
    func status(for memberId: String, mealTime: MealTime, in plan: DayPlan?) -> MealStatus {
        guard let plan else { return .undecided }
        guard let target = plan.memberPlans.first(where: { $0.memberId == memberId }) else {
            return .undecided
        }
        return target.status(for: mealTime)
    }

    /// 指定メンバーのメモを返します。
    func note(for memberId: String, in plan: DayPlan?) -> String {
        guard let plan else { return "" }
        guard let target = plan.memberPlans.first(where: { $0.memberId == memberId }) else {
            return ""
        }
        return target.note
    }
}

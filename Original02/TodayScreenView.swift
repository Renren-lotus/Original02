//
//  TodayScreenView.swift
//  Original02
//
//  Created by Codex on 2026/05/27.
//

import SwiftUI

/// 今日の食事予定を表示する画面です。
struct TodayScreenView: View {
    let groupId: String
    let members: [GroupMember]
    let homeCountBreakfast: Int
    let homeCountLunch: Int
    let homeCountDinner: Int
    let statusProvider: (String, MealTime) -> MealStatus
    let canEditMember: (String) -> Bool
    let onCycleStatus: (String, MealTime) -> Void
    let onOpenEditor: (String) -> Void
    let onOpenGroupSettings: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            headerArea
            countArea
                .padding(.top, 18)

            Divider()
                .padding(.vertical, 16)

            ScrollView {
                VStack(spacing: 14) {
                    ForEach(members) { member in
                        familyRow(member: member)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .background(AppThemeColor.baseBackground)
    }

    /// 画面上部のタイトル情報です。
    private var headerArea: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date().jpMonthDay)
                    .font(.system(size: 20, weight: .semibold))
                Text("グループID: \(groupId)")
                    .font(.system(size: 14))
                    .foregroundStyle(AppThemeColor.accent.opacity(0.8))
            }

            Spacer()

            Button {
                onOpenGroupSettings()
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20))
                    .foregroundStyle(AppThemeColor.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    /// 朝昼夜の人数表示エリアです。
    private var countArea: some View {
        HStack(spacing: 18) {
            countCard(title: MealTime.breakfast.rawValue, count: homeCountBreakfast)
            countCard(title: MealTime.lunch.rawValue, count: homeCountLunch)
            countCard(title: MealTime.dinner.rawValue, count: homeCountDinner)
        }
        .padding(.horizontal, 20)
    }

    /// 人数表示の小さなカードです。
    private func countCard(title: String, count: Int) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .medium))
            Text("\(count)食")
                .font(.system(size: 28, weight: .bold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppThemeColor.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppThemeColor.support, lineWidth: 1)
        )
    }

    /// 家族1人分の行です。
    private func familyRow(member: GroupMember) -> some View {
        let editable = canEditMember(member.id)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(member.name)
                    .font(.system(size: 18, weight: .medium))
                if member.isCurrentUser {
                    Text("(自分)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppThemeColor.accent)
                }
            }

            HStack(spacing: 18) {
                ForEach(MealTime.allCases) { mealTime in
                    Button {
                        onCycleStatus(member.id, mealTime)
                    } label: {
                        MealStatusCircle(status: statusProvider(member.id, mealTime))
                    }
                    .buttonStyle(.plain)
                    .disabled(!editable)
                    .opacity(editable ? 1.0 : 0.5)
                }

                Spacer()

                if editable {
                    Button {
                        onOpenEditor(member.id)
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(AppThemeColor.accent)
                    }
                    .buttonStyle(.plain)
                } else {
                    Image(systemName: "lock")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(AppThemeColor.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppThemeColor.support, lineWidth: 1)
        )
    }
}

#Preview {
    let samplePlan = DayPlan(
        date: Date(),
        groupId: "A3FK9Q",
        memberPlans: [
            MemberMealPlan(memberId: "me", name: "自分", breakfast: .home, lunch: .out, dinner: .home),
            MemberMealPlan(memberId: "other", name: "父", breakfast: .home, lunch: .home, dinner: .out)
        ]
    )

    TodayScreenView(
        groupId: "A3FK9Q",
        members: [
            GroupMember(id: "me", name: "自分", isCurrentUser: true),
            GroupMember(id: "other", name: "父", isCurrentUser: false)
        ],
        homeCountBreakfast: 2,
        homeCountLunch: 1,
        homeCountDinner: 1,
        statusProvider: { memberId, meal in
            samplePlan.memberPlans.first(where: { $0.memberId == memberId })?.status(for: meal) ?? .undecided
        },
        canEditMember: { $0 == "me" },
        onCycleStatus: { _, _ in },
        onOpenEditor: { _ in },
        onOpenGroupSettings: { }
    )
}

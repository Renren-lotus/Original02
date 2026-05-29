//
//  WeekScreenView.swift
//  Original02
//
//  Created by Codex on 2026/05/27.
//

import SwiftUI

/// 1週間分の予定一覧を表示する画面です。
struct WeekScreenView: View {
    let plans: [DayPlan]
    let onEditDate: (Date) -> Void

    var body: some View {
        let dates = weekDates()

        ScrollView {
            VStack(spacing: 12) {
                ForEach(dates, id: \.self) { date in
                    weekRow(for: date)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(AppThemeColor.baseBackground)
    }

    /// 1週間分の日付配列を作ります。
    private func weekDates() -> [Date] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: start)
        }
    }

    /// 1日分の行を作ります。
    private func weekRow(for date: Date) -> some View {
        let targetPlan = plans.first(where: { $0.dayKey == DayPlan.dayKey(from: date) })

        return HStack(spacing: 12) {
            Text(date.jpMonthDayWeekday)
                .font(.system(size: 18, weight: .medium))
                .frame(width: 92, alignment: .leading)

            HStack(spacing: 16) {
                ForEach(MealTime.allCases) { meal in
                    MealStatusCircle(status: summaryStatus(for: meal, in: targetPlan))
                }
            }

            Spacer()

            Button {
                onEditDate(date)
            } label: {
                Image(systemName: "pencil.circle")
                    .font(.system(size: 24))
                    .foregroundStyle(AppThemeColor.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppThemeColor.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppThemeColor.support, lineWidth: 1)
        )
    }

    /// 1日の代表状態を返します。
    private func summaryStatus(for mealTime: MealTime, in plan: DayPlan?) -> MealStatus {
        guard let plan else { return .undecided }

        let homeCount = plan.memberPlans.filter { $0.status(for: mealTime) == .home }.count
        let outCount = plan.memberPlans.filter { $0.status(for: mealTime) == .out }.count

        if homeCount > 0 {
            return .home
        }
        if outCount > 0 {
            return .out
        }
        return .undecided
    }
}

#Preview {
    WeekScreenView(plans: [], onEditDate: { _ in })
}

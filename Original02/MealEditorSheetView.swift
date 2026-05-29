//
//  MealEditorSheetView.swift
//  Original02
//
//  Created by Codex on 2026/05/27.
//

import SwiftUI

/// 食事予定を入力するモーダル画面です。
struct MealEditorSheetView: View {
    let targetDate: Date
    let currentUserName: String
    let existingMemberPlan: MemberMealPlan?
    let onCancel: () -> Void
    let onSave: (MealStatus, MealStatus, MealStatus, String) -> Void

    @State private var breakfast: MealStatus = .undecided
    @State private var lunch: MealStatus = .undecided
    @State private var dinner: MealStatus = .undecided
    @State private var note: String = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("閉じる") {
                    onCancel()
                }
                .foregroundStyle(AppThemeColor.accent)

                Spacer()

                Text(targetDate.jpMonthDayWeekday)
                    .font(.system(size: 18, weight: .semibold))

                Spacer()

                Color.clear
                    .frame(width: 40, height: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Form {
                Section("入力者") {
                    Text(currentUserName)
                        .font(.system(size: 18, weight: .medium))
                }
                .listRowBackground(AppThemeColor.cardBackground)

                Section("食事") {
                    mealSelectorRow(title: MealTime.breakfast.rawValue, selection: $breakfast)
                    mealSelectorRow(title: MealTime.lunch.rawValue, selection: $lunch)
                    mealSelectorRow(title: MealTime.dinner.rawValue, selection: $dinner)
                }
                .listRowBackground(AppThemeColor.cardBackground)

                Section("メモ") {
                    TextField("メモを入力", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
                .listRowBackground(AppThemeColor.cardBackground)
            }
            .scrollContentBackground(.hidden)
            .background(AppThemeColor.baseBackground)

            Button {
                onSave(breakfast, lunch, dinner, note)
            } label: {
                Text("保存")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppThemeColor.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 22)
            .background(AppThemeColor.baseBackground)
        }
        .background(AppThemeColor.baseBackground)
        .onAppear {
            setupInitialState()
        }
    }

    /// 食事選択行を表示します。
    private func mealSelectorRow(title: String, selection: Binding<MealStatus>) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .frame(width: 44, alignment: .leading)

            Spacer()

            HStack(spacing: 12) {
                mealChoiceButton(label: "未定", status: .undecided, selection: selection)
                mealChoiceButton(label: "家", status: .home, selection: selection)
                mealChoiceButton(label: "外", status: .out, selection: selection)
            }
        }
        .padding(.vertical, 4)
    }

    /// 1つの食事選択ボタンを表示します。
    private func mealChoiceButton(label: String, status: MealStatus, selection: Binding<MealStatus>) -> some View {
        Button {
            selection.wrappedValue = status
        } label: {
            VStack(spacing: 6) {
                MealStatusCircle(status: status == selection.wrappedValue ? status : .undecided)
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(.black)
            }
            .frame(width: 44)
        }
        .buttonStyle(.plain)
    }

    /// 初回表示時の状態を設定します。
    private func setupInitialState() {
        guard let existingMemberPlan else { return }
        breakfast = existingMemberPlan.breakfast
        lunch = existingMemberPlan.lunch
        dinner = existingMemberPlan.dinner
        note = existingMemberPlan.note
    }
}

#Preview {
    MealEditorSheetView(
        targetDate: Date(),
        currentUserName: "れん",
        existingMemberPlan: nil,
        onCancel: { },
        onSave: { _, _, _, _ in }
    )
}

//
//  ContentView.swift
//  Original02
//
//  Created by 坂下蓮 on 2026/05/27.
//

import SwiftUI
import SwiftData

/// アプリのホーム画面全体を表示するViewです。
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DayPlan.date) private var dayPlans: [DayPlan]
    @State private var viewModel = MealPlannerViewModel()
    @State private var session = LocalGroupSession()

    /// 画面の初期化を行います。
    init() { }

    var body: some View {
        @Bindable var bindableViewModel = viewModel

        let plansInGroup = dayPlans.filter { $0.groupId == session.groupId }
        let todayPlan = viewModel.plan(for: Date(), groupId: session.groupId, in: plansInGroup)
        let members = viewModel.members(
            groupId: session.groupId,
            currentUserId: session.currentUserId,
            currentUserName: session.currentUserName,
            plans: plansInGroup
        )
        let editingTargetPlan = viewModel.plan(for: viewModel.editingDate, groupId: session.groupId, in: plansInGroup)
        let currentUserPlan = editingTargetPlan?.memberPlans.first(where: { $0.memberId == session.currentUserId })

        VStack(spacing: 0) {
            HomeTabHeader(selectedPage: $bindableViewModel.selectedPage)
                .padding(.top, 8)
                .padding(.horizontal, 20)

            TabView(selection: $bindableViewModel.selectedPage) {
                TodayScreenView(
                    groupId: session.groupId,
                    members: members,
                    homeCountBreakfast: viewModel.homeCount(for: .breakfast, in: todayPlan),
                    homeCountLunch: viewModel.homeCount(for: .lunch, in: todayPlan),
                    homeCountDinner: viewModel.homeCount(for: .dinner, in: todayPlan),
                    statusProvider: { memberId, meal in
                        viewModel.status(for: memberId, mealTime: meal, in: todayPlan)
                    },
                    canEditMember: { memberId in
                        viewModel.canEdit(memberId: memberId, currentUserId: session.currentUserId)
                    },
                    onCycleStatus: { memberId, meal in
                        viewModel.cycleStatus(
                            for: memberId,
                            mealTime: meal,
                            date: Date(),
                            groupId: session.groupId,
                            currentUserId: session.currentUserId,
                            currentUserName: session.currentUserName,
                            plans: plansInGroup,
                            context: modelContext
                        )
                    },
                    onOpenEditor: { memberId in
                        let canEdit = viewModel.canEdit(memberId: memberId, currentUserId: session.currentUserId)
                        viewModel.openEditor(for: Date(), canEdit: canEdit)
                    },
                    onOpenGroupSettings: {
                        viewModel.openGroupSettings()
                    }
                )
                .tag(HomePage.today)

                WeekScreenView(
                    plans: plansInGroup,
                    onEditDate: { targetDate in
                        viewModel.openEditor(for: targetDate, canEdit: true)
                    }
                )
                .tag(HomePage.week)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.2), value: viewModel.selectedPage)
        }
        .background(AppThemeColor.baseBackground)
        .sheet(isPresented: $bindableViewModel.showingEditor) {
            MealEditorSheetView(
                targetDate: viewModel.editingDate,
                currentUserName: session.currentUserName,
                existingMemberPlan: currentUserPlan,
                onCancel: {
                    viewModel.closeEditor()
                },
                onSave: { breakfast, lunch, dinner, note in
                    viewModel.saveOwnPlan(
                        for: viewModel.editingDate,
                        groupId: session.groupId,
                        currentUserId: session.currentUserId,
                        currentUserName: session.currentUserName,
                        breakfast: breakfast,
                        lunch: lunch,
                        dinner: dinner,
                        note: note,
                        plans: plansInGroup,
                        context: modelContext
                    )
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $bindableViewModel.showingGroupSettings) {
            GroupSettingsSheetView(
                userName: session.currentUserName,
                groupId: session.groupId,
                onClose: {
                    viewModel.closeGroupSettings()
                },
                onLeaveGroup: {
                    viewModel.closeGroupSettings()
                    session.clearGroup()
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { !session.isSetupCompleted },
                set: { _ in }
            )
        ) {
            GroupSetupView(
                onCreateGroup: { userName in
                    session.createGroup(userName: userName)
                },
                onJoinGroup: { userName, groupId in
                    session.joinGroup(userName: userName, groupId: groupId)
                }
            )
        }
    }
}

/// 今日・今週タブを上部に表示するViewです。
private struct HomeTabHeader: View {
    @Binding var selectedPage: HomePage

    var body: some View {
        HStack(spacing: 28) {
            ForEach(HomePage.allCases) { page in
                Button {
                    selectedPage = page
                } label: {
                    VStack(spacing: 6) {
                        Text(page.title)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(selectedPage == page ? AppThemeColor.accent : .black)

                        Rectangle()
                            .fill(selectedPage == page ? AppThemeColor.accent : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(width: 54)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: DayPlan.self, inMemory: true)
}

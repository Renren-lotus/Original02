//
//  Original02App.swift
//  Original02
//
//  Created by 坂下蓮 on 2026/05/27.
//

import SwiftUI
import SwiftData

@main
struct Original02App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: DayPlan.self)
    }
}

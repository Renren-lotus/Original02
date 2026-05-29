//
//  MealStatusCircleView.swift
//  Original02
//
//  Created by Codex on 2026/05/27.
//

import SwiftUI

/// 食事の状態を円で表示する共通部品です。
struct MealStatusCircle: View {
    let status: MealStatus

    var body: some View {
        Circle()
            .strokeBorder(AppThemeColor.accent.opacity(0.9), lineWidth: 1.2)
            .background(
                Circle()
                    .fill(fillColor)
            )
            .frame(width: 34, height: 34)
    }

    /// 状態に合わせた塗り色を返します。
    private var fillColor: Color {
        switch status {
        case .undecided:
            return .white
        case .home:
            return AppThemeColor.accent
        case .out:
            return AppThemeColor.support
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        MealStatusCircle(status: .undecided)
        MealStatusCircle(status: .home)
        MealStatusCircle(status: .out)
    }
    .padding()
    .background(AppThemeColor.baseBackground)
}

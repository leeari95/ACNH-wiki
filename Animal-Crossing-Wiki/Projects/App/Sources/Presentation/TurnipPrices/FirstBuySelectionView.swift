//
//  FirstBuySelectionView.swift
//  ACNH-wiki
//
//  Created by Ari on 12/28/25.
//

import SwiftUI

struct FirstBuySelectionView: View {
    @State private var isFirstBuy: Bool
    private var onFirstBuyChanged: ((Bool) -> Void)?

    init(isFirstBuy: Bool = false, onFirstBuyChanged: ((Bool) -> Void)? = nil) {
        _isFirstBuy = State(initialValue: isFirstBuy)
        self.onFirstBuyChanged = onFirstBuyChanged
    }

    var body: some View {
        HStack {
            Text("firstBuyTitle".localized)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(SwiftUI.Color(uiColor: .acText))
            
            Spacer()
            
            HStack(spacing: 8) {
                RadioButton(
                    title: "yes".localized,
                    isSelected: isFirstBuy
                ) {
                    isFirstBuy = true
                    onFirstBuyChanged?(true)
                }
                RadioButton(
                    title: "no".localized,
                    isSelected: !isFirstBuy
                ) {
                    isFirstBuy = false
                    onFirstBuyChanged?(false)
                }
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 6)
    }
}

// MARK: - Radio Button Component

private struct RadioButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                circleView
                labelView
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? SwiftUI.Color(uiColor: .catalogSelected).opacity(0.2) : SwiftUI.Color.clear)
            )
        }
    }

    private var circleView: some View {
        ZStack {
            Circle()
                .stroke(
                    isSelected ? SwiftUI.Color(uiColor: .catalogSelected) : SwiftUI.Color(uiColor: .acText).opacity(0.3),
                    lineWidth: 2
                )
                .frame(width: 20, height: 20)

            if isSelected {
                Circle()
                    .fill(SwiftUI.Color(uiColor: .catalogSelected))
                    .frame(width: 12, height: 12)
            }
        }
    }

    private var labelView: some View {
        Text(title)
            .font(.system(size: 14, weight: isSelected ? .bold : .regular))
            .foregroundStyle(isSelected ? SwiftUI.Color(uiColor: .catalogSelected) : SwiftUI.Color(uiColor: .acText))
            .frame(width: 45)
    }
}

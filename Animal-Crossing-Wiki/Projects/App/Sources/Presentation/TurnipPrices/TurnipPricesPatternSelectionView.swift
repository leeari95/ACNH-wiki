//
//  TurnipPricesPatternSelectionView.swift
//  ACNH-wiki
//
//  Created by Ari on 12/17/25.
//

import SwiftUI

enum TurnipPricePattern: Int, CaseIterable {
    case unknown = -1
    case fluctuating = 0
    case largespike = 1
    case decreasing = 2
    case smallspike = 3

    var displayText: String {
        switch self {
        case .unknown:
            return "❓ 모름"
        case .fluctuating:
            return "📊 변동형"
        case .largespike:
            return "📈 큰폭 상승"
        case .smallspike:
            return "📉 작은폭 상승"
        case .decreasing:
            return "👎 계속 하락"
        }
    }
}

struct TurnipPricesPatternSelectionView: View {
    @State private var selectedPattern: TurnipPricePattern
    @State private var showingPatternSelection = false
    private var onPatternSelected: ((TurnipPricePattern) -> Void)?

    init(selectedPattern: TurnipPricePattern = .unknown, onPatternSelected: ((TurnipPricePattern) -> Void)? = nil) {
        _selectedPattern = State(initialValue: selectedPattern)
        self.onPatternSelected = onPatternSelected
    }

    var body: some View {
        HStack {
            Text("turnipPricePattern".localized)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(SwiftUI.Color(uiColor: .acText))

            Spacer()

            Capsule()
                .fill(SwiftUI.Color(uiColor: .catalogBar))
                .frame(width: 190, height: 35)
                .overlay {
                    Text(selectedPattern.displayText)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(SwiftUI.Color(uiColor: .black))
                }
                .onTapGesture {
                    showingPatternSelection = true
                }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 6)
        .confirmationDialog(
            "selectTurnipPricePattern".localized,
            isPresented: $showingPatternSelection,
            titleVisibility: .visible
        ) {
            ForEach(TurnipPricePattern.allCases, id: \.self) { pattern in
                Button(pattern.displayText) {
                    selectedPattern = pattern
                    onPatternSelected?(pattern)
                }
            }
        }
    }
}

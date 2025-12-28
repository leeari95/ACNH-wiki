//
//  TurnipPricesPatternSelectionView.swift
//  ACNH-wiki
//
//  Created by Ari on 12/17/25.
//

import SwiftUI

enum TurnipPricePattern: CaseIterable {
    case unknown
    case fluctuating
    case largespike
    case smallspike
    case decreasing

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
    @State private var selectedPattern: TurnipPricePattern = .unknown
    @State private var showingPatternSelection = false

    var body: some View {
        HStack {
            Text("turnipPricePattern".localized)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)

            Spacer()

            Capsule()
                .fill(SwiftUI.Color(uiColor: .catalogBar))
                .frame(width: 190, height: 35)
                .overlay {
                    Text(selectedPattern.displayText)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(SwiftUI.Color(uiColor: .acBackground))
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
                }
            }
        }
    }
}

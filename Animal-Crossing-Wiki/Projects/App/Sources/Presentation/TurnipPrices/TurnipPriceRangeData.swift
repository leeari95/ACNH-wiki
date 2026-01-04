//
//  TurnipPriceRangeData.swift
//  ACNH-wiki
//
//  Created by Ari on 12/28/25.
//

import SwiftUI

struct TurnipPriceRangeData: Identifiable {
    let id = UUID()
    let day: String
    let dayOrder: Int
    let period: String
    let minPrice: Int
    let maxPrice: Int
    let basePrice: Int

    var avgPrice: Int {
        (minPrice + maxPrice) / 2
    }

    var avgRatio: Float {
        guard basePrice > 0 else {
            return 0
        }
        return Float(avgPrice) / Float(basePrice)
    }

    var isUserInput: Bool {
        minPrice == maxPrice
    }

    var color: SwiftUI.Color {
        if avgRatio >= 2.0 {
            return .green
        } else if avgRatio >= 1.0 {
            return SwiftUI.Color(uiColor: .catalogBar)
        } else if avgRatio >= 0.8 {
            return .orange
        } else {
            return .red
        }
    }
}

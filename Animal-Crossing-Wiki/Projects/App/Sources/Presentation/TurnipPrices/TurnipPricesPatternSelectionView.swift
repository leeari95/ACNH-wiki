//
//  TurnipPricesPatternSelectionView.swift
//  ACNH-wiki
//
//  Created by Ari on 12/17/25.
//

import SwiftUI

struct TurnipPricesPatternSelectionView: View {
    var body: some View {
        HStack {
            Text("📉 작은폭 상승")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
            
            Spacer()
            
            Capsule()
                .fill(SwiftUI.Color(uiColor: .catalogBar))
                .frame(width: 190, height: 35)
                .overlay {
                    Text("📉 작은폭 상승")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(SwiftUI.Color(uiColor: .acBackground))
                }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 6)
    }
}

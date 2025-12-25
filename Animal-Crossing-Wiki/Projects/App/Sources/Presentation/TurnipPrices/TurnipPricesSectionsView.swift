//
//  TurnipPricesSectionsView.swift
//  ACNH-wiki
//
//  Created by Ari on 12/24/25.
//

import SwiftUI

struct TurnipPricesSectionsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: .zero) {
                SectionContainerView(
                    title: "turnipPatternSectionTitle".localized,
                    iconName: "checkmark.circle.dotted"
                ) {
                    TurnipPricesPatternSelectionView()
                }
                .padding(.bottom, 25)

                SectionContainerView(
                    title: "turnipPriceSectionTitle".localized,
                    iconName: "pencil"
                ) {
                    TurnipPricesInputView()
                }
                .padding(.bottom, 14)

                HStack {
                    Spacer()

                    RoundedRectangle(cornerRadius: 14)
                        .fill(SwiftUI.Color(uiColor: .catalogBackground))
                        .frame(width: 72)
                        .overlay {
                            Text("reset".localized)
                                .foregroundColor(SwiftUI.Color(uiColor: .acText))
                                .font(.system(size: 14, weight: .bold))
                        }

                    RoundedRectangle(cornerRadius: 14)
                        .fill(SwiftUI.Color(uiColor: .catalogBar))
                        .frame(width: 93)
                        .overlay {
                            Text("showResults".localized)
                                .foregroundColor(SwiftUI.Color.black)
                                .font(.system(size: 14, weight: .bold))
                        }
                }
                .frame(height: 36)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 60)
        }
        .scrollIndicators(.hidden)
        .contentShape(Rectangle())
        .onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
        .background(SwiftUI.Color(uiColor: .acBackground))
    }
}

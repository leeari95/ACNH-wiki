//
//  TurnipPricesSectionsView.swift
//  ACNH-wiki
//
//  Created by Ari on 12/24/25.
//

import SwiftUI

struct TurnipPricesSectionsView: View {
    let reactor: TurnipPricesReactor

    var body: some View {
        ScrollView {
            VStack(spacing: .zero) {
                SectionContainerView(
                    title: "firstBuyDescription".localized,
                    iconName: "questionmark.circle"
                ) {
                    FirstBuySelectionView(
                        onFirstBuyChanged: { isFirstBuy in
                            reactor.action.onNext(.updateFirstBuy(isFirstBuy))
                        }
                    )
                }
                .padding(.bottom, 25)

                SectionContainerView(
                    title: "turnipPatternSectionTitle".localized,
                    iconName: "checkmark.circle.dotted"
                ) {
                    TurnipPricesPatternSelectionView(
                        onPatternSelected: { pattern in
                            reactor.action.onNext(.selectPattern(pattern))
                        }
                    )
                }
                .padding(.bottom, 25)

                SectionContainerView(
                    title: "turnipPriceSectionTitle".localized,
                    iconName: "pencil"
                ) {
                    TurnipPricesInputView(
                        onSundayPriceChanged: { price in
                            reactor.action.onNext(.updateSundayPrice(price))
                        },
                        onPriceChanged: { day, period, price in
                            reactor.action.onNext(.updatePrice(day: day, period: period, price: price))
                        }
                    )
                }
                .padding(.bottom, 14)

                HStack {
                    Spacer()

                    RoundedRectangle(cornerRadius: 14)
                        .fill(SwiftUI.Color(uiColor: .catalogBackground))
                        .frame(width: 72)
                        .overlay {
                            Text("turnipReset".localized)
                                .foregroundColor(SwiftUI.Color(uiColor: .acText))
                                .font(.system(size: 14, weight: .bold))
                        }
                        .onTapGesture {
                            // TODO: 초기화 기능 추가
                        }

                    RoundedRectangle(cornerRadius: 14)
                        .fill(SwiftUI.Color(uiColor: .catalogBar))
                        .frame(width: 93)
                        .overlay {
                            Text("showResults".localized)
                                .foregroundColor(SwiftUI.Color.black)
                                .font(.system(size: 14, weight: .bold))
                        }
                        .onTapGesture {
                            reactor.action.onNext(.calculate)
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

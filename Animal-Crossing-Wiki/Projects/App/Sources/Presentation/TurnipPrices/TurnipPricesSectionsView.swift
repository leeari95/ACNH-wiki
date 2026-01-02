//
//  TurnipPricesSectionsView.swift
//  ACNH-wiki
//
//  Created by Ari on 12/24/25.
//

import SwiftUI

struct TurnipPricesSectionsView: View {
    let reactor: TurnipPricesReactor
    @State private var inputViewID = UUID()

    var body: some View {
        ScrollView {
            VStack(spacing: .zero) {
                SectionContainerView(
                    title: "firstBuyDescription".localized,
                    iconName: "questionmark.circle"
                ) {
                    FirstBuySelectionView(
                        isFirstBuy: reactor.currentState.isFirstBuy,
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
                        selectedPattern: reactor.currentState.selectedPattern,
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
                        sunday: reactor.currentState.sundayPrice,
                        mondayAM: reactor.currentState.prices[.monday]?[.am] ?? "",
                        mondayPM: reactor.currentState.prices[.monday]?[.pm] ?? "",
                        tuesdayAM: reactor.currentState.prices[.tuesday]?[.am] ?? "",
                        tuesdayPM: reactor.currentState.prices[.tuesday]?[.pm] ?? "",
                        wednesdayAM: reactor.currentState.prices[.wednesday]?[.am] ?? "",
                        wednesdayPM: reactor.currentState.prices[.wednesday]?[.pm] ?? "",
                        thursdayAM: reactor.currentState.prices[.thursday]?[.am] ?? "",
                        thursdayPM: reactor.currentState.prices[.thursday]?[.pm] ?? "",
                        fridayAM: reactor.currentState.prices[.friday]?[.am] ?? "",
                        fridayPM: reactor.currentState.prices[.friday]?[.pm] ?? "",
                        saturdayAM: reactor.currentState.prices[.saturday]?[.am] ?? "",
                        saturdayPM: reactor.currentState.prices[.saturday]?[.pm] ?? "",
                        onSundayPriceChanged: { price in
                            reactor.action.onNext(.updateSundayPrice(price))
                        },
                        onPriceChanged: { day, period, price in
                            reactor.action.onNext(.updatePrice(day: day, period: period, price: price))
                        }
                    )
                    .id(inputViewID)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 68)
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
        .overlay(alignment: .bottom) {
            buttonBar
        }
        .background(SwiftUI.Color(uiColor: .acBackground))
    }

    private var buttonBar: some View {
        HStack {
            Spacer()

            RoundedRectangle(cornerRadius: 14)
                .fill(SwiftUI.Color(uiColor: .catalogBackground))
                .frame(width: 72, height: 36)
                .overlay {
                    Text("turnipReset".localized)
                        .foregroundColor(SwiftUI.Color(uiColor: .acText))
                        .font(.system(size: 14, weight: .bold))
                }
                .onTapGesture {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                    reactor.action.onNext(.reset)
                    inputViewID = UUID()
                }

            RoundedRectangle(cornerRadius: 14)
                .fill(SwiftUI.Color(uiColor: .catalogBar))
                .frame(width: 93, height: 36)
                .overlay {
                    Text("showResults".localized)
                        .foregroundColor(SwiftUI.Color.black)
                        .font(.system(size: 14, weight: .bold))
                }
                .onTapGesture {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                    reactor.action.onNext(.calculate)
                }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

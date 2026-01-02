//
//  TurnipPricesInputView.swift
//  ACNH-wiki
//
//  Created by Ari on 12/23/25.
//

import UIKit
import SwiftUI

struct TurnipPricesInputView: View {
    @State var sunday: String
    @State var mondayAM: String
    @State var mondayPM: String
    @State var tuesdayAM: String
    @State var tuesdayPM: String
    @State var wednesdayAM: String
    @State var wednesdayPM: String
    @State var thursdayAM: String
    @State var thursdayPM: String
    @State var fridayAM: String
    @State var fridayPM: String
    @State var saturdayAM: String
    @State var saturdayPM: String

    private var onSundayPriceChanged: ((String) -> Void)?
    private var onPriceChanged: ((TurnipPricesReactor.DayOfWeek, TurnipPricesReactor.Period, String) -> Void)?

    // MARK: - Initialization

    init(
        sunday: String = "",
        mondayAM: String = "",
        mondayPM: String = "",
        tuesdayAM: String = "",
        tuesdayPM: String = "",
        wednesdayAM: String = "",
        wednesdayPM: String = "",
        thursdayAM: String = "",
        thursdayPM: String = "",
        fridayAM: String = "",
        fridayPM: String = "",
        saturdayAM: String = "",
        saturdayPM: String = "",
        onSundayPriceChanged: ((String) -> Void)? = nil,
        onPriceChanged: ((TurnipPricesReactor.DayOfWeek, TurnipPricesReactor.Period, String) -> Void)? = nil
    ) {
        _sunday = State(initialValue: sunday)
        _mondayAM = State(initialValue: mondayAM)
        _mondayPM = State(initialValue: mondayPM)
        _tuesdayAM = State(initialValue: tuesdayAM)
        _tuesdayPM = State(initialValue: tuesdayPM)
        _wednesdayAM = State(initialValue: wednesdayAM)
        _wednesdayPM = State(initialValue: wednesdayPM)
        _thursdayAM = State(initialValue: thursdayAM)
        _thursdayPM = State(initialValue: thursdayPM)
        _fridayAM = State(initialValue: fridayAM)
        _fridayPM = State(initialValue: fridayPM)
        _saturdayAM = State(initialValue: saturdayAM)
        _saturdayPM = State(initialValue: saturdayPM)
        self.onSundayPriceChanged = onSundayPriceChanged
        self.onPriceChanged = onPriceChanged
    }

    var body: some View {
        VStack(spacing: 15) {
            HStack(spacing: 30) {
                Text("sunday".localized)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(SwiftUI.Color(uiColor: .acText))

                RoundedRectangle(cornerRadius: 14)
                    .fill(SwiftUI.Color(uiColor: .acBackground))
                    .frame(height: 54)
                    .overlay {
                        TextField(
                            "",
                            text: $sunday,
                            prompt: Text("purchasePrice".localized)
                                .foregroundColor(SwiftUI.Color(uiColor: .acText).opacity(0.3))
                                .font(.system(size: 17, weight: .regular))
                        )
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(SwiftUI.Color(uiColor: .acText))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .onChange(of: sunday) { newValue in
                            onSundayPriceChanged?(newValue)
                        }
                    }
            }

            dayRow(label: "monday".localized, day: .monday, amBinding: $mondayAM, pmBinding: $mondayPM)
            dayRow(label: "tuesday".localized, day: .tuesday, amBinding: $tuesdayAM, pmBinding: $tuesdayPM)
            dayRow(label: "wednesday".localized, day: .wednesday, amBinding: $wednesdayAM, pmBinding: $wednesdayPM)
            dayRow(label: "thursday".localized, day: .thursday, amBinding: $thursdayAM, pmBinding: $thursdayPM)
            dayRow(label: "friday".localized, day: .friday, amBinding: $fridayAM, pmBinding: $fridayPM)
            dayRow(label: "saturday".localized, day: .saturday, amBinding: $saturdayAM, pmBinding: $saturdayPM)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 6)
    }

    // MARK: - Private Methods

    @ViewBuilder
    private func dayRow(label: String, day: TurnipPricesReactor.DayOfWeek, amBinding: Binding<String>, pmBinding: Binding<String>) -> some View {
        HStack(spacing: 30) {
            Text(label)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(SwiftUI.Color(uiColor: .acText))

            RoundedRectangle(cornerRadius: 14)
                .fill(SwiftUI.Color(uiColor: .acBackground))
                .frame(height: 54)
                .overlay {
                    TextField(
                        "",
                        text: amBinding,
                        prompt: Text("am".localized)
                            .foregroundColor(SwiftUI.Color(uiColor: .acText).opacity(0.3))
                            .font(.system(size: 17, weight: .regular))
                    )
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(SwiftUI.Color(uiColor: .acText))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .onChange(of: amBinding.wrappedValue) { newValue in
                        onPriceChanged?(day, .am, newValue)
                    }
                }

            RoundedRectangle(cornerRadius: 14)
                .fill(SwiftUI.Color(uiColor: .acBackground))
                .frame(height: 54)
                .overlay {
                    TextField(
                        "",
                        text: pmBinding,
                        prompt: Text("pm".localized)
                            .foregroundColor(SwiftUI.Color(uiColor: .acText).opacity(0.3))
                            .font(.system(size: 17, weight: .regular))
                    )
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(SwiftUI.Color(uiColor: .acText))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .onChange(of: pmBinding.wrappedValue) { newValue in
                        onPriceChanged?(day, .pm, newValue)
                    }
                }
        }
    }
}

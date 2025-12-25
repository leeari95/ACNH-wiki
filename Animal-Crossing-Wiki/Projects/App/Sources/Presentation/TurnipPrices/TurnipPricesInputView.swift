//
//  TurnipPricesInputView.swift
//  ACNH-wiki
//
//  Created by Ari on 12/23/25.
//

import UIKit
import SwiftUI

struct TurnipPricesInputView: View {
    @State var sunday: String = ""
    @State var mondayAM: String = ""
    @State var mondayPM: String = ""
    @State var tuesdayAM: String = ""
    @State var tuesdayPM: String = ""
    @State var wednesdayAM: String = ""
    @State var wednesdayPM: String = ""
    @State var thursdayAM: String = ""
    @State var thursdayPM: String = ""
    @State var fridayAM: String = ""
    @State var fridayPM: String = ""
    @State var saturdayAM: String = ""
    @State var saturdayPM: String = ""

    var body: some View {
        VStack(spacing: 15) {
            // 일요일
            HStack(spacing: 30) {
                Text("sunday".localized)
                    .font(.system(size: 17, weight: .semibold))

                RoundedRectangle(cornerRadius: 14)
                    .fill(SwiftUI.Color(uiColor: .acBackground))
                    .frame(height: 54)
                    .overlay {
                        TextField(
                            "",
                            text: $sunday,
                            prompt: Text("purchasePrice".localized)
                                .foregroundColor(.white.opacity(0.3))
                                .font(.system(size: 17, weight: .regular))
                        )
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(SwiftUI.Color(uiColor: .acText))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                    }
            }

            dayRow(label: "monday".localized, amBinding: $mondayAM, pmBinding: $mondayPM)
            dayRow(label: "tuesday".localized, amBinding: $tuesdayAM, pmBinding: $tuesdayPM)
            dayRow(label: "wednesday".localized, amBinding: $wednesdayAM, pmBinding: $wednesdayPM)
            dayRow(label: "thursday".localized, amBinding: $thursdayAM, pmBinding: $thursdayPM)
            dayRow(label: "friday".localized, amBinding: $fridayAM, pmBinding: $fridayPM)
            dayRow(label: "saturday".localized, amBinding: $saturdayAM, pmBinding: $saturdayPM)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 6)
    }

    @ViewBuilder
    private func dayRow(label: String, amBinding: Binding<String>, pmBinding: Binding<String>) -> some View {
        HStack(spacing: 30) {
            Text(label)
                .font(.system(size: 17, weight: .semibold))

            RoundedRectangle(cornerRadius: 14)
                .fill(SwiftUI.Color(uiColor: .acBackground))
                .frame(height: 54)
                .overlay {
                    TextField(
                        "",
                        text: amBinding,
                        prompt: Text("am".localized)
                            .foregroundColor(.white.opacity(0.3))
                            .font(.system(size: 17, weight: .regular))
                    )
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(SwiftUI.Color(uiColor: .acText))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                }

            RoundedRectangle(cornerRadius: 14)
                .fill(SwiftUI.Color(uiColor: .acBackground))
                .frame(height: 54)
                .overlay {
                    TextField(
                        "",
                        text: pmBinding,
                        prompt: Text("pm".localized)
                            .foregroundColor(.white.opacity(0.3))
                            .font(.system(size: 17, weight: .regular))
                    )
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(SwiftUI.Color(uiColor: .acText))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                }
        }
    }
}

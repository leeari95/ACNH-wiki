//
//  TurnipPriceResultView.swift
//  ACNH-wiki
//
//  Created by Ari on 12/28/25.
//

import SwiftUI
import Charts

// MARK: - Chart Data Model

struct TurnipPriceData: Identifiable {
    let id = UUID()
    let day: String
    let dayOrder: Int
    let period: String
    let price: Int
    let basePrice: Int

    var ratio: Float {
        Float(price) / Float(basePrice)
    }

    var color: SwiftUI.Color {
        if ratio >= 2.0 {
            return .green
        } else if ratio >= 1.0 {
            return SwiftUI.Color(uiColor: .catalogBar)
        } else if ratio >= 0.8 {
            return .orange
        } else {
            return .red
        }
    }
}

struct TurnipPriceResultView: View {
    let basePrice: Int
    let pattern: TurnipPricePattern
    let prices: [TurnipPricesReactor.DayOfWeek: [TurnipPricesReactor.Period: Int]]
    @Environment(\.dismiss) private var dismiss

    // Chart 데이터 생성
    private var chartData: [TurnipPriceData] {
        TurnipPricesReactor.DayOfWeek.allCases.enumerated().flatMap { index, day in
            [
                TurnipPriceData(
                    day: dayShortLabel(day),
                    dayOrder: index,
                    period: "AM",
                    price: prices[day]?[.am] ?? 0,
                    basePrice: basePrice
                ),
                TurnipPriceData(
                    day: dayShortLabel(day),
                    dayOrder: index,
                    period: "PM",
                    price: prices[day]?[.pm] ?? 0,
                    basePrice: basePrice
                )
            ]
        }
    }

    var body: some View {
        ZStack {
            // 배경
            SwiftUI.Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // 메인 컨텐츠
            VStack(spacing: 0) {
                // 헤더
                HStack {
                    Text("무 가격 예측 결과")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(SwiftUI.Color(uiColor: .acText))

                    Spacer()

                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(SwiftUI.Color(uiColor: .catalogBar).opacity(0.6))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

                // 패턴 및 구매가 정보
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("패턴")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(SwiftUI.Color(uiColor: .acText).opacity(0.6))
                        Text(pattern.displayText)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(SwiftUI.Color(uiColor: .acText))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("일요일 구매가")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(SwiftUI.Color(uiColor: .acText).opacity(0.6))
                        Text("\(basePrice) 벨")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(SwiftUI.Color(uiColor: .catalogBar))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)

                // 차트
                ScrollView(.horizontal, showsIndicators: false) {
                    Chart {
                        ForEach(chartData) { data in
                            BarMark(
                                x: .value("요일", "\(data.day)\n\(data.period)"),
                                y: .value("가격", data.price)
                            )
                            .foregroundStyle(data.color)
                            .annotation(position: .top) {
                                Text("\(data.price)")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(SwiftUI.Color(uiColor: .acText))
                            }
                        }

                        // 기준선 (구매가)
                        RuleMark(y: .value("구매가", basePrice))
                            .foregroundStyle(SwiftUI.Color(uiColor: .catalogBar).opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                            .annotation(position: .trailing, alignment: .center) {
                                Text("구매가: \(basePrice)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(SwiftUI.Color(uiColor: .acText).opacity(0.8))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(SwiftUI.Color(uiColor: .acBackground))
                            }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let label = value.as(String.self) {
                                    Text(label)
                                        .font(.system(size: 8, weight: .medium))
                                        .foregroundColor(SwiftUI.Color(uiColor: .acText))
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: .automatic) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let intValue = value.as(Int.self) {
                                    Text("\(intValue)")
                                        .font(.system(size: 10))
                                        .foregroundColor(SwiftUI.Color(uiColor: .acText).opacity(0.6))
                                }
                            }
                        }
                    }
                    .frame(width: 600, height: 350)
                    .padding(.vertical, 20)
                }
                .padding(.horizontal, 24)
            }
            .frame(maxWidth: 500)
            .background(SwiftUI.Color(uiColor: .acBackground))
            .cornerRadius(20)
            .padding(.horizontal, 30)
        }
    }

    private func dayLabel(_ day: TurnipPricesReactor.DayOfWeek) -> String {
        switch day {
        case .monday: return "monday".localized
        case .tuesday: return "tuesday".localized
        case .wednesday: return "wednesday".localized
        case .thursday: return "thursday".localized
        case .friday: return "friday".localized
        case .saturday: return "saturday".localized
        }
    }

    private func dayShortLabel(_ day: TurnipPricesReactor.DayOfWeek) -> String {
        switch day {
        case .monday: return "월"
        case .tuesday: return "화"
        case .wednesday: return "수"
        case .thursday: return "목"
        case .friday: return "금"
        case .saturday: return "토"
        }
    }
}

// MARK: - Preview

#Preview {
    let samplePrices: [TurnipPricesReactor.DayOfWeek: [TurnipPricesReactor.Period: Int]] = [
        .monday: [.am: 95, .pm: 92],
        .tuesday: [.am: 88, .pm: 140],
        .wednesday: [.am: 180, .pm: 500],
        .thursday: [.am: 140, .pm: 95],
        .friday: [.am: 70, .pm: 65],
        .saturday: [.am: 60, .pm: 55]
    ]

    return TurnipPriceResultView(
        basePrice: 100,
        pattern: .largespike,
        prices: samplePrices
    )
}

//
//  TurnipPriceResultView.swift
//  ACNH-wiki
//
//  Created by Ari on 12/28/25.
//

import SwiftUI
import Charts

// MARK: - Chart Data Model

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
        Float(avgPrice) / Float(basePrice)
    }

    /// 사용자 입력값인지 여부 (min == max)
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

struct TurnipPriceResultView: View {
    let basePrice: Int
    let pattern: TurnipPricePattern
    let minPrices: [TurnipPricesReactor.DayOfWeek: [TurnipPricesReactor.Period: Int]]
    let maxPrices: [TurnipPricesReactor.DayOfWeek: [TurnipPricesReactor.Period: Int]]
    @Environment(\.dismiss) private var dismiss

    // Chart 데이터 생성
    private var chartData: [TurnipPriceRangeData] {
        TurnipPricesReactor.DayOfWeek.allCases.enumerated().flatMap { index, day in
            [
                TurnipPriceRangeData(
                    day: dayShortLabel(day),
                    dayOrder: index,
                    period: "AM",
                    minPrice: minPrices[day]?[.am] ?? 0,
                    maxPrice: maxPrices[day]?[.am] ?? 0,
                    basePrice: basePrice
                ),
                TurnipPriceRangeData(
                    day: dayShortLabel(day),
                    dayOrder: index,
                    period: "PM",
                    minPrice: minPrices[day]?[.pm] ?? 0,
                    maxPrice: maxPrices[day]?[.pm] ?? 0,
                    basePrice: basePrice
                )
            ]
        }
    }

    // Y축 최대값 계산
    private var maxYValue: Int {
        let maxPrice = chartData.map { $0.maxPrice }.max() ?? 0
        // 여유를 두기 위해 10% 추가하고 10 단위로 올림
        let buffer = Int(Double(maxPrice) * 0.1)
        return ((maxPrice + buffer) / 10 + 1) * 10
    }

    var body: some View {
        ZStack {
            // 배경
            SwiftUI.Color.clear
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
                            if data.isUserInput {
                                // 사용자 입력값: 0부터 입력값까지 막대그래프
                                RectangleMark(
                                    x: .value("요일", "\(data.day)\n\(data.period)"),
                                    yStart: .value("시작", 0),
                                    yEnd: .value("입력값", data.minPrice),
                                    width: 35
                                )
                                .foregroundStyle(data.color.opacity(0.7))

                                // 입력값 포인트 및 라벨
                                PointMark(
                                    x: .value("요일", "\(data.day)\n\(data.period)"),
                                    y: .value("입력값", data.minPrice)
                                )
                                .symbol(.circle)
                                .symbolSize(60)
                                .foregroundStyle(data.color)
                                .annotation(position: .top, spacing: 4) {
                                    Text("\(data.minPrice)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(data.color)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(SwiftUI.Color(uiColor: .acBackground).opacity(0.95))
                                        .cornerRadius(6)
                                }
                            } else {
                                // 예측값: 범위 막대 + min/max 마커
                                // 최소~최대 범위 막대
                                RectangleMark(
                                    x: .value("요일", "\(data.day)\n\(data.period)"),
                                    yStart: .value("최소", data.minPrice),
                                    yEnd: .value("최대", data.maxPrice),
                                    width: 35
                                )
                                .foregroundStyle(data.color)

                                // 최대값 포인트 및 라벨
                                PointMark(
                                    x: .value("요일", "\(data.day)\n\(data.period)"),
                                    y: .value("최대", data.maxPrice)
                                )
                                .symbol(.circle)
                                .symbolSize(40)
                                .foregroundStyle(SwiftUI.Color.green.opacity(0.7))
                                .annotation(position: .top, spacing: 2) {
                                    Text("최대 \(data.maxPrice)")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(SwiftUI.Color(uiColor: .acBackground).opacity(0.95))
                                        .cornerRadius(4)
                                }

                                // 최소값 포인트 및 라벨
                                PointMark(
                                    x: .value("요일", "\(data.day)\n\(data.period)"),
                                    y: .value("최소", data.minPrice)
                                )
                                .symbol(.diamond)
                                .symbolSize(50)
                                .foregroundStyle(SwiftUI.Color.red.opacity(0.8))
                                .annotation(position: .bottom, spacing: 4) {
                                    Text("최소 \(data.minPrice)")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.red)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(SwiftUI.Color(uiColor: .acBackground).opacity(0.95))
                                        .cornerRadius(4)
                                }
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
                    .chartYScale(domain: 0...maxYValue)
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
                    .padding(.trailing, 40)
                }
                .padding(.horizontal, 24)
            }
            .frame(maxWidth: 500)
            .background(SwiftUI.Color(uiColor: .acSecondaryBackground))
            .cornerRadius(20)
            .padding(.horizontal, 20)
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
        case .monday: return "mondayShort".localized
        case .tuesday: return "tuesdayShort".localized
        case .wednesday: return "wednesdayShort".localized
        case .thursday: return "thursdayShort".localized
        case .friday: return "fridayShort".localized
        case .saturday: return "saturdayShort".localized
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleMinPrices: [TurnipPricesReactor.DayOfWeek: [TurnipPricesReactor.Period: Int]] = [
        .monday: [.am: 90, .pm: 85],
        .tuesday: [.am: 80, .pm: 130],
        .wednesday: [.am: 170, .pm: 480],
        .thursday: [.am: 130, .pm: 85],
        .friday: [.am: 60, .pm: 55],
        .saturday: [.am: 50, .pm: 45]
    ]

    let sampleMaxPrices: [TurnipPricesReactor.DayOfWeek: [TurnipPricesReactor.Period: Int]] = [
        .monday: [.am: 100, .pm: 100],
        .tuesday: [.am: 95, .pm: 150],
        .wednesday: [.am: 190, .pm: 520],
        .thursday: [.am: 150, .pm: 105],
        .friday: [.am: 80, .pm: 75],
        .saturday: [.am: 70, .pm: 65]
    ]

    return TurnipPriceResultView(
        basePrice: 100,
        pattern: .largespike,
        minPrices: sampleMinPrices,
        maxPrices: sampleMaxPrices
    )
}

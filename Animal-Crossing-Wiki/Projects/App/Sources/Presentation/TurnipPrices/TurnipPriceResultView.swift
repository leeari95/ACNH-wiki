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

// MARK: - Main View

struct TurnipPriceResultView: View {
    let basePrice: Int
    let pattern: TurnipPricePattern
    let minPrices: [TurnipPricesReactor.DayOfWeek: [TurnipPricesReactor.Period: Int]]
    let maxPrices: [TurnipPricesReactor.DayOfWeek: [TurnipPricesReactor.Period: Int]]
    @Environment(\.dismiss) private var dismiss

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

    private var maxYValue: Int {
        let maxPrice = chartData.map { $0.maxPrice }.max() ?? 0
        let buffer = Int(Double(maxPrice) * 0.1)
        return ((maxPrice + buffer) / 10 + 1) * 10
    }

    var body: some View {
        ZStack {
            dismissableBackgroundView

            contentView
                .frame(maxWidth: 500)
                .background(SwiftUI.Color(uiColor: .acSecondaryBackground))
                .cornerRadius(20)
                .padding(.horizontal, 20)
        }
    }
}

// MARK: - Background

private extension TurnipPriceResultView {
    var dismissableBackgroundView: some View {
        SwiftUI.Color.clear
            .ignoresSafeArea()
            .onTapGesture {
                dismiss()
            }
    }
}

// MARK: - Content

private extension TurnipPriceResultView {
    var contentView: some View {
        VStack(spacing: 0) {
            headerView
            priceInfoView
            chartScrollView
        }
    }

    var headerView: some View {
        HStack {
            Text("무 가격 예측 결과")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(SwiftUI.Color(uiColor: .acText))

            Spacer()

            closeButton
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    var closeButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(SwiftUI.Color(uiColor: .catalogBar).opacity(0.6))
        }
    }

    var priceInfoView: some View {
        HStack(spacing: 20) {
            PatternInfoView(pattern: pattern)
            Spacer()
            BasePriceInfoView(basePrice: basePrice)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
}

// MARK: - Info Views

private struct PatternInfoView: View {
    let pattern: TurnipPricePattern

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("패턴")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(SwiftUI.Color(uiColor: .acText).opacity(0.6))
            Text(pattern.displayText)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(SwiftUI.Color(uiColor: .acText))
        }
    }
}

private struct BasePriceInfoView: View {
    let basePrice: Int

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("일요일 구매가")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(SwiftUI.Color(uiColor: .acText).opacity(0.6))
            Text("\(basePrice) 벨")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(SwiftUI.Color(uiColor: .catalogBar))
        }
    }
}

// MARK: - Chart

private extension TurnipPriceResultView {
    var chartScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            priceChart
                .frame(width: 600, height: 350)
                .padding(.vertical, 20)
                .padding(.trailing, 40)
        }
        .padding(.horizontal, 24)
    }

    var priceChart: some View {
        Chart {
            ForEach(chartData) { data in
                if data.isUserInput {
                    userInputChartMarks(for: data)
                } else {
                    predictionChartMarks(for: data)
                }
            }

            basePriceRuleMark
        }
        .chartXAxis { chartXAxis }
        .chartYScale(domain: 0...maxYValue)
        .chartYAxis { chartYAxis }
    }

    var basePriceRuleMark: some ChartContent {
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

    @AxisContentBuilder
    var chartXAxis: some AxisContent {
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

    @AxisContentBuilder
    var chartYAxis: some AxisContent {
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
}

// MARK: - Chart Marks

private extension TurnipPriceResultView {
    @ChartContentBuilder
    func userInputChartMarks(for data: TurnipPriceRangeData) -> some ChartContent {
        userInputBarMark(for: data)
        userInputPointMark(for: data)
    }

    func userInputBarMark(for data: TurnipPriceRangeData) -> some ChartContent {
        RectangleMark(
            x: .value("요일", "\(data.day)\n\(data.period)"),
            yStart: .value("시작", 0),
            yEnd: .value("입력값", data.minPrice),
            width: 35
        )
        .foregroundStyle(data.color.opacity(0.7))
    }

    func userInputPointMark(for data: TurnipPriceRangeData) -> some ChartContent {
        PointMark(
            x: .value("요일", "\(data.day)\n\(data.period)"),
            y: .value("입력값", data.minPrice)
        )
        .symbol(.circle)
        .symbolSize(60)
        .foregroundStyle(data.color)
        .annotation(position: .top, spacing: 4) {
            PriceLabel(
                price: data.minPrice,
                color: data.color,
                fontSize: 10,
                cornerRadius: 6
            )
        }
    }

    @ChartContentBuilder
    func predictionChartMarks(for data: TurnipPriceRangeData) -> some ChartContent {
        predictionRangeMark(for: data)
        maxPricePointMark(for: data)
        minPricePointMark(for: data)
    }

    func predictionRangeMark(for data: TurnipPriceRangeData) -> some ChartContent {
        RectangleMark(
            x: .value("요일", "\(data.day)\n\(data.period)"),
            yStart: .value("최소", data.minPrice),
            yEnd: .value("최대", data.maxPrice),
            width: 35
        )
        .foregroundStyle(data.color)
    }

    func maxPricePointMark(for data: TurnipPriceRangeData) -> some ChartContent {
        PointMark(
            x: .value("요일", "\(data.day)\n\(data.period)"),
            y: .value("최대", data.maxPrice)
        )
        .symbol(.circle)
        .symbolSize(40)
        .foregroundStyle(SwiftUI.Color.green.opacity(0.7))
        .annotation(position: .top, spacing: 2) {
            PriceLabel(
                price: data.maxPrice,
                color: .green,
                prefix: "최대 ",
                fontSize: 9,
                cornerRadius: 4
            )
        }
    }

    func minPricePointMark(for data: TurnipPriceRangeData) -> some ChartContent {
        PointMark(
            x: .value("요일", "\(data.day)\n\(data.period)"),
            y: .value("최소", data.minPrice)
        )
        .symbol(.diamond)
        .symbolSize(50)
        .foregroundStyle(SwiftUI.Color.red.opacity(0.8))
        .annotation(position: .bottom, spacing: 4) {
            PriceLabel(
                price: data.minPrice,
                color: .red,
                prefix: "최소 ",
                fontSize: 9,
                cornerRadius: 4
            )
        }
    }
}

// MARK: - Supporting Views

private struct PriceLabel: View {
    let price: Int
    let color: SwiftUI.Color
    var prefix: String = ""
    let fontSize: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        Text("\(prefix)\(price)")
            .font(.system(size: fontSize, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, fontSize > 9 ? 8 : 6)
            .padding(.vertical, fontSize > 9 ? 4 : 2)
            .background(SwiftUI.Color(uiColor: .acBackground).opacity(0.95))
            .cornerRadius(cornerRadius)
    }
}

// MARK: - Helper Methods

private extension TurnipPriceResultView {
    func dayLabel(_ day: TurnipPricesReactor.DayOfWeek) -> String {
        switch day {
        case .monday: return "monday".localized
        case .tuesday: return "tuesday".localized
        case .wednesday: return "wednesday".localized
        case .thursday: return "thursday".localized
        case .friday: return "friday".localized
        case .saturday: return "saturday".localized
        }
    }

    func dayShortLabel(_ day: TurnipPricesReactor.DayOfWeek) -> String {
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

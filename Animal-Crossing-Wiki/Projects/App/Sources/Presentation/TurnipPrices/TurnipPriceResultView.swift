//
//  TurnipPriceResultView.swift
//  ACNH-wiki
//
//  Created by Ari on 12/28/25.
//

import SwiftUI
import Charts

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
        contentView
            .frame(maxWidth: 500)
            .background(SwiftUI.Color(uiColor: .acSecondaryBackground))
            .cornerRadius(20)
            .padding(.horizontal, 20)
    }

    private var contentView: some View {
        VStack(spacing: 0) {
            headerView
            priceInfoView
            chartScrollView
        }
    }

    private var headerView: some View {
        HStack {
            Text("turnipPriceResultTitle".localized)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(SwiftUI.Color(uiColor: .acText))

            Spacer()

            closeButton
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    private var closeButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(SwiftUI.Color(uiColor: .catalogBar).opacity(0.6))
        }
    }

    private var priceInfoView: some View {
        HStack(spacing: 20) {
            PatternInfoView(pattern: pattern)
            Spacer()
            BasePriceInfoView(basePrice: basePrice)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    private var chartScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            priceChart
                .frame(width: 600, height: 350)
                .padding(.vertical, 20)
                .padding(.trailing, 40)
        }
        .padding(.horizontal, 24)
    }

    private var priceChart: some View {
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

    private var basePriceRuleMark: some ChartContent {
        RuleMark(y: .value("purchasePriceLabel".localized, basePrice))
            .foregroundStyle(SwiftUI.Color(uiColor: .catalogBar).opacity(0.5))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
            .annotation(position: .trailing, alignment: .center) {
                Text("\("purchasePriceLabel".localized): \(basePrice)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(SwiftUI.Color(uiColor: .acText).opacity(0.8))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(SwiftUI.Color(uiColor: .acBackground))
            }
    }

    @AxisContentBuilder
    private var chartXAxis: some AxisContent {
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
    private var chartYAxis: some AxisContent {
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

    @ChartContentBuilder
    private func userInputChartMarks(for data: TurnipPriceRangeData) -> some ChartContent {
        userInputBarMark(for: data)
        userInputPointMark(for: data)
    }

    private func userInputBarMark(for data: TurnipPriceRangeData) -> some ChartContent {
        RectangleMark(
            x: .value("요일", "\(data.day)\n\(data.period)"),
            yStart: .value("시작", 0),
            yEnd: .value("입력값", data.minPrice),
            width: 35
        )
        .foregroundStyle(data.color.opacity(0.7))
    }

    private func userInputPointMark(for data: TurnipPriceRangeData) -> some ChartContent {
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
    private func predictionChartMarks(for data: TurnipPriceRangeData) -> some ChartContent {
        predictionRangeMark(for: data)
        maxPricePointMark(for: data)
        minPricePointMark(for: data)
    }

    private func predictionRangeMark(for data: TurnipPriceRangeData) -> some ChartContent {
        RectangleMark(
            x: .value("요일", "\(data.day)\n\(data.period)"),
            yStart: .value("minLabel".localized, data.minPrice),
            yEnd: .value("maxLabel".localized, data.maxPrice),
            width: 35
        )
        .foregroundStyle(data.color)
    }

    private func maxPricePointMark(for data: TurnipPriceRangeData) -> some ChartContent {
        PointMark(
            x: .value("요일", "\(data.day)\n\(data.period)"),
            y: .value("maxLabel".localized, data.maxPrice)
        )
        .symbol(.circle)
        .symbolSize(40)
        .foregroundStyle(SwiftUI.Color.green.opacity(0.7))
        .annotation(position: .top, spacing: 2) {
            PriceLabel(
                price: data.maxPrice,
                color: .green,
                prefix: "\("maxLabel".localized) ",
                fontSize: 9,
                cornerRadius: 4
            )
        }
    }

    private func minPricePointMark(for data: TurnipPriceRangeData) -> some ChartContent {
        PointMark(
            x: .value("요일", "\(data.day)\n\(data.period)"),
            y: .value("minLabel".localized, data.minPrice)
        )
        .symbol(.diamond)
        .symbolSize(50)
        .foregroundStyle(SwiftUI.Color.red.opacity(0.8))
        .annotation(position: .bottom, spacing: 4) {
            PriceLabel(
                price: data.minPrice,
                color: .red,
                prefix: "\("minLabel".localized) ",
                fontSize: 9,
                cornerRadius: 4
            )
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

// MARK: - Info Views

private struct PatternInfoView: View {
    let pattern: TurnipPricePattern

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("pattern".localized)
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
            Text("sundayPurchasePrice".localized)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(SwiftUI.Color(uiColor: .acText).opacity(0.6))
            Text("\(basePrice) \("bellUnit".localized)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(SwiftUI.Color(uiColor: .catalogBar))
        }
    }
}

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

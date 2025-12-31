//
//  TurnipPrice.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation

/// 무 가격 패턴 타입
enum TurnipPattern: String, CaseIterable {
    case fluctuating = "Fluctuating"      // 변동형
    case largeSpikePattern = "Large Spike" // 3기형 (대폭등)
    case decreasing = "Decreasing"         // 감소형
    case smallSpike = "Small Spike"        // 4기형 (소폭등)
    case unknown = "Unknown"               // 알 수 없음

    var localizedName: String {
        return rawValue.localized
    }

    var description: String {
        switch self {
        case .fluctuating:
            return "Prices fluctuate up and down throughout the week.".localized
        case .largeSpikePattern:
            return "Prices drop then spike dramatically, peaking at 200-600 bells.".localized
        case .decreasing:
            return "Prices continuously decrease throughout the week.".localized
        case .smallSpike:
            return "Prices drop then rise moderately, peaking at 140-200 bells.".localized
        case .unknown:
            return "Not enough data to predict the pattern.".localized
        }
    }
}

/// 주간 무 가격 데이터
struct TurnipPrice: Equatable {
    let id: UUID
    let weekStartDate: Date
    let buyPrice: Int?
    let prices: [Int?] // 12개 (월~토 오전/오후)
    let createdDate: Date

    init(
        id: UUID = UUID(),
        weekStartDate: Date = Date().startOfWeek,
        buyPrice: Int? = nil,
        prices: [Int?] = Array(repeating: nil, count: 12),
        createdDate: Date = Date()
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.buyPrice = buyPrice
        self.prices = prices.count == 12 ? prices : Array(repeating: nil, count: 12)
        self.createdDate = createdDate
    }
}

extension TurnipPrice {
    /// 가격 인덱스 (0: 월 오전, 1: 월 오후, 2: 화 오전, ...)
    static let dayLabels = ["Mon AM", "Mon PM", "Tue AM", "Tue PM", "Wed AM", "Wed PM",
                            "Thu AM", "Thu PM", "Fri AM", "Fri PM", "Sat AM", "Sat PM"]

    /// 특정 인덱스의 가격 업데이트
    func updatePrice(at index: Int, price: Int?) -> TurnipPrice {
        guard index >= 0 && index < 12 else { return self }
        var newPrices = prices
        newPrices[index] = price
        return TurnipPrice(
            id: id,
            weekStartDate: weekStartDate,
            buyPrice: buyPrice,
            prices: newPrices,
            createdDate: createdDate
        )
    }

    /// 구매 가격 업데이트
    func updateBuyPrice(_ newBuyPrice: Int?) -> TurnipPrice {
        return TurnipPrice(
            id: id,
            weekStartDate: weekStartDate,
            buyPrice: newBuyPrice,
            prices: prices,
            createdDate: createdDate
        )
    }

    /// 입력된 가격 개수
    var enteredPriceCount: Int {
        return prices.compactMap { $0 }.count
    }

    /// 구매 가격 대비 비율 계산
    func priceRatio(at index: Int) -> Double? {
        guard let buyPrice = buyPrice, buyPrice > 0,
              let sellPrice = prices[index] else { return nil }
        return Double(sellPrice) / Double(buyPrice)
    }
}

// MARK: - Date Extension for Week
extension Date {
    /// 주의 시작일 (일요일) 반환
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }

    /// 같은 주인지 확인
    func isSameWeek(as date: Date) -> Bool {
        return startOfWeek == date.startOfWeek
    }
}

//
//  TurnipPriceCalculator.swift
//  ACNH-wiki
//
//  Created by Ari on 12/28/25.
//

import Foundation

/// 무 가격 계산기
/// 원본 알고리즘: https://github.com/simontime/Resead
final class TurnipPriceCalculator {
    private let rng: SeadRandom

    /// 일요일 구매가 (90~110 벨)
    private(set) var basePrice: Int = 0

    /// 판매가 배열 [0-1: 미사용, 2-3: 월요일 AM/PM, 4-5: 화요일 AM/PM, ..., 12-13: 토요일 AM/PM]
    private(set) var sellPrices: [Int] = Array(repeating: 0, count: 14)

    /// 현재 패턴
    private(set) var currentPattern: TurnipPricePattern = .unknown

    init(rng: SeadRandom = SeadRandom()) {
        self.rng = rng
    }

    /// 무 가격 계산
    /// - Parameter previousPattern: 저번 주 패턴 (nil이면 무작위)
    func calculate(previousPattern: TurnipPricePattern? = nil) {
        // 기본 구매가 설정 (90~110)
        basePrice = rng.getInt(min: 90, max: 110)

        // 다음 패턴 결정
        if let previous = previousPattern, previous != .unknown {
            currentPattern = selectNextPattern(from: previous)
        } else {
            currentPattern = TurnipPricePattern(rawValue: rng.getInt(min: 0, max: 3)) ?? .fluctuating
        }

        // 가격 배열 초기화
        sellPrices = Array(repeating: 0, count: 14)

        // 패턴별 가격 계산
        switch currentPattern {
        case .fluctuating:
            calculateFluctuatingPattern()
        case .largespike:
            calculateLargeSpikePattern()
        case .decreasing:
            calculateDecreasingPattern()
        case .smallspike:
            calculateSmallSpikePattern()
        case .unknown:
            break
        }
    }

    /// 다음 패턴 선택
    private func selectNextPattern(from previous: TurnipPricePattern) -> TurnipPricePattern {
        let chance = rng.getInt(min: 0, max: 99)

        switch previous {
        case .fluctuating:
            if chance < 20 { return .fluctuating } else if chance < 50 { return .largespike } else if chance < 65 { return .decreasing } else { return .smallspike }

        case .largespike:
            if chance < 50 { return .fluctuating } else if chance < 55 { return .largespike } else if chance < 75 { return .decreasing } else { return .smallspike }

        case .decreasing:
            if chance < 25 { return .fluctuating } else if chance < 70 { return .largespike } else if chance < 75 { return .decreasing } else { return .smallspike }

        case .smallspike:
            if chance < 45 { return .fluctuating } else if chance < 70 { return .largespike } else if chance < 85 { return .decreasing } else { return .smallspike }

        case .unknown:
            return TurnipPricePattern(rawValue: rng.getInt(min: 0, max: 3)) ?? .fluctuating
        }
    }

    // MARK: - Pattern 0: Fluctuating (변동형)

    private func calculateFluctuatingPattern() {
        var work = 2

        // 하락 구간 길이 결정
        let decPhaseLen1 = rng.getBool() ? 3 : 2
        let decPhaseLen2 = 5 - decPhaseLen1

        // 상승 구간 길이 결정
        let hiPhaseLen1 = rng.getInt(min: 0, max: 6)
        let hiPhaseLen2and3 = 7 - hiPhaseLen1
        let hiPhaseLen3 = rng.getInt(min: 0, max: hiPhaseLen2and3 - 1)

        // 상승 구간 1
        for _ in 0..<hiPhaseLen1 {
            sellPrices[work] = intCeil(rng.getFloat(min: 0.9, max: 1.4) * Float(basePrice))
            work += 1
        }

        // 하락 구간 1
        var rate = rng.getFloat(min: 0.6, max: 0.8)
        for _ in 0..<decPhaseLen1 {
            sellPrices[work] = intCeil(rate * Float(basePrice))
            work += 1
            rate -= 0.04
            rate -= rng.getFloat(min: 0, max: 0.06)
        }

        // 상승 구간 2
        for _ in 0..<(hiPhaseLen2and3 - hiPhaseLen3) {
            sellPrices[work] = intCeil(rng.getFloat(min: 0.9, max: 1.4) * Float(basePrice))
            work += 1
        }

        // 하락 구간 2
        rate = rng.getFloat(min: 0.6, max: 0.8)
        for _ in 0..<decPhaseLen2 {
            sellPrices[work] = intCeil(rate * Float(basePrice))
            work += 1
            rate -= 0.04
            rate -= rng.getFloat(min: 0, max: 0.06)
        }

        // 상승 구간 3
        for _ in 0..<hiPhaseLen3 {
            sellPrices[work] = intCeil(rng.getFloat(min: 0.9, max: 1.4) * Float(basePrice))
            work += 1
        }
    }

    // MARK: - Pattern 1: Large Spike (큰폭 상승)

    private func calculateLargeSpikePattern() {
        let peakStart = rng.getInt(min: 3, max: 9)
        var work = 2

        // 피크 전 하락 구간
        var rate = rng.getFloat(min: 0.85, max: 0.9)
        for _ in 2..<peakStart {
            sellPrices[work] = intCeil(rate * Float(basePrice))
            work += 1
            rate -= 0.03
            rate -= rng.getFloat(min: 0, max: 0.02)
        }

        // 상승 스파이크 (5회)
        sellPrices[work] = intCeil(rng.getFloat(min: 0.9, max: 1.4) * Float(basePrice))
        work += 1
        sellPrices[work] = intCeil(rng.getFloat(min: 1.4, max: 2.0) * Float(basePrice))
        work += 1
        sellPrices[work] = intCeil(rng.getFloat(min: 2.0, max: 6.0) * Float(basePrice))
        work += 1
        sellPrices[work] = intCeil(rng.getFloat(min: 1.4, max: 2.0) * Float(basePrice))
        work += 1
        sellPrices[work] = intCeil(rng.getFloat(min: 0.9, max: 1.4) * Float(basePrice))
        work += 1

        // 피크 후 낮은 가격
        while work < 14 {
            sellPrices[work] = intCeil(rng.getFloat(min: 0.4, max: 0.9) * Float(basePrice))
            work += 1
        }
    }

    // MARK: - Pattern 2: Decreasing (계속 하락)

    private func calculateDecreasingPattern() {
        var rate: Float = 0.9
        rate -= rng.getFloat(min: 0, max: 0.05)

        var work = 2
        while work < 14 {
            sellPrices[work] = intCeil(rate * Float(basePrice))
            work += 1
            rate -= 0.03
            rate -= rng.getFloat(min: 0, max: 0.02)
        }
    }

    // MARK: - Pattern 3: Small Spike (작은폭 상승)

    private func calculateSmallSpikePattern() {
        let peakStart = rng.getInt(min: 2, max: 9)
        var work = 2

        // 피크 전 하락 구간
        var rate = rng.getFloat(min: 0.4, max: 0.9)
        for _ in 2..<peakStart {
            sellPrices[work] = intCeil(rate * Float(basePrice))
            work += 1
            rate -= 0.03
            rate -= rng.getFloat(min: 0, max: 0.02)
        }

        // 상승 스파이크 (5회)
        sellPrices[work] = intCeil(rng.getFloat(min: 0.9, max: 1.4) * Float(basePrice))
        work += 1
        sellPrices[work] = intCeil(rng.getFloat(min: 0.9, max: 1.4) * Float(basePrice))
        work += 1

        let peakRate = rng.getFloat(min: 1.4, max: 2.0)
        sellPrices[work] = intCeil(rng.getFloat(min: 1.4, max: peakRate) * Float(basePrice)) - 1
        work += 1
        sellPrices[work] = intCeil(peakRate * Float(basePrice))
        work += 1
        sellPrices[work] = intCeil(rng.getFloat(min: 1.4, max: peakRate) * Float(basePrice)) - 1
        work += 1

        // 피크 후 하락 구간
        if work < 14 {
            rate = rng.getFloat(min: 0.4, max: 0.9)
            while work < 14 {
                sellPrices[work] = intCeil(rate * Float(basePrice))
                work += 1
                rate -= 0.03
                rate -= rng.getFloat(min: 0, max: 0.02)
            }
        }
    }

    // MARK: - Utility

    private func intCeil(_ value: Float) -> Int {
        return Int(value + 0.99999)
    }

    /// 특정 요일/시간대의 가격 가져오기
    func getPrice(day: TurnipPricesReactor.DayOfWeek, period: TurnipPricesReactor.Period) -> Int {
        let index = dayPeriodToIndex(day: day, period: period)
        return sellPrices[index]
    }

    /// 요일/시간대를 배열 인덱스로 변환
    private func dayPeriodToIndex(day: TurnipPricesReactor.DayOfWeek, period: TurnipPricesReactor.Period) -> Int {
        let dayOffset: Int
        switch day {
        case .monday: dayOffset = 2
        case .tuesday: dayOffset = 4
        case .wednesday: dayOffset = 6
        case .thursday: dayOffset = 8
        case .friday: dayOffset = 10
        case .saturday: dayOffset = 12
        }

        return dayOffset + (period == .pm ? 1 : 0)
    }
}

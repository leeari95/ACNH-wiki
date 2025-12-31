//
//  TurnipPricePredictor.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation

/// 무 가격 예측 결과
struct TurnipPrediction: Equatable {
    let pattern: TurnipPattern
    let probability: Double
    let minPrice: Int
    let maxPrice: Int
    let expectedPrices: [ClosedRange<Int>?]

    static let unknown = TurnipPrediction(
        pattern: .unknown,
        probability: 0,
        minPrice: 0,
        maxPrice: 0,
        expectedPrices: Array(repeating: nil, count: 12)
    )
}

/// 무 가격 패턴 예측기
struct TurnipPricePredictor {

    // MARK: - Pattern Analysis

    /// 입력된 가격 데이터로 패턴 예측
    static func predict(turnipPrice: TurnipPrice) -> [TurnipPrediction] {
        guard let buyPrice = turnipPrice.buyPrice, buyPrice > 0 else {
            return [.unknown]
        }

        let ratios = turnipPrice.prices.map { price -> Double? in
            guard let p = price else { return nil }
            return Double(p) / Double(buyPrice)
        }

        var predictions: [TurnipPrediction] = []

        // 각 패턴에 대한 확률 및 예상 가격 범위 계산
        let fluctuatingPrediction = analyzeFluctuating(buyPrice: buyPrice, ratios: ratios)
        let largeSpikePrediction = analyzeLargeSpike(buyPrice: buyPrice, ratios: ratios)
        let decreasingPrediction = analyzeDecreasing(buyPrice: buyPrice, ratios: ratios)
        let smallSpikePrediction = analyzeSmallSpike(buyPrice: buyPrice, ratios: ratios)

        predictions.append(fluctuatingPrediction)
        predictions.append(largeSpikePrediction)
        predictions.append(decreasingPrediction)
        predictions.append(smallSpikePrediction)

        // 확률로 정렬
        return predictions.sorted { $0.probability > $1.probability }
    }

    /// 예상 최고/최저가 반환
    static func getExpectedPriceRange(turnipPrice: TurnipPrice) -> (min: Int, max: Int)? {
        guard let buyPrice = turnipPrice.buyPrice, buyPrice > 0 else { return nil }

        let predictions = predict(turnipPrice: turnipPrice)
        guard let topPrediction = predictions.first, topPrediction.pattern != .unknown else {
            // 기본 범위: 40% ~ 600%
            return (Int(Double(buyPrice) * 0.4), Int(Double(buyPrice) * 6.0))
        }

        return (topPrediction.minPrice, topPrediction.maxPrice)
    }

    // MARK: - Pattern Specific Analysis

    /// 변동형 패턴 분석
    private static func analyzeFluctuating(buyPrice: Int, ratios: [Double?]) -> TurnipPrediction {
        // 변동형: 0.6 ~ 1.4 범위 내에서 오르내림
        let minRatio = 0.6
        let maxRatio = 1.4
        var probability = 0.35 // 기본 확률 35%

        let validRatios = ratios.compactMap { $0 }
        if !validRatios.isEmpty {
            let withinRange = validRatios.filter { $0 >= minRatio && $0 <= maxRatio }
            let variance = calculateVariance(validRatios)

            // 모든 값이 범위 내이고 변동이 있으면 확률 증가
            if withinRange.count == validRatios.count && variance > 0.01 && variance < 0.1 {
                probability = min(0.8, probability + Double(validRatios.count) * 0.05)
            } else if withinRange.count < validRatios.count {
                probability = 0.1
            }
        }

        let expectedPrices = (0..<12).map { _ -> ClosedRange<Int>? in
            let min = Int(Double(buyPrice) * minRatio)
            let max = Int(Double(buyPrice) * maxRatio)
            return min...max
        }

        return TurnipPrediction(
            pattern: .fluctuating,
            probability: probability,
            minPrice: Int(Double(buyPrice) * minRatio),
            maxPrice: Int(Double(buyPrice) * maxRatio),
            expectedPrices: expectedPrices
        )
    }

    /// 3기형 (대폭등) 패턴 분석
    private static func analyzeLargeSpike(buyPrice: Int, ratios: [Double?]) -> TurnipPrediction {
        // 3기형: 감소 -> 급등 (2~6배) -> 급락
        var probability = 0.25 // 기본 확률 25%

        let validRatios = ratios.compactMap { $0 }
        if validRatios.count >= 3 {
            // 스파이크 탐지
            var foundSpike = false
            for i in 1..<validRatios.count - 1 {
                if validRatios[i] > 1.5 && validRatios[i] > validRatios[i-1] {
                    foundSpike = true
                    probability = 0.7
                    break
                }
            }

            // 초반 감소 패턴 탐지
            if validRatios.count >= 2 && validRatios[0] < 1.0 && validRatios[1] < validRatios[0] {
                probability += 0.1
            }

            if !foundSpike && validRatios.allSatisfy({ $0 < 1.0 }) {
                probability = 0.4 // 아직 스파이크 전일 수 있음
            }
        }

        let expectedPrices: [ClosedRange<Int>?] = (0..<12).map { index in
            if index < 4 {
                // 초반 감소
                let min = Int(Double(buyPrice) * (0.4 - Double(index) * 0.05))
                let max = Int(Double(buyPrice) * (0.9 - Double(index) * 0.03))
                return max(min, 40)...max
            } else if index < 7 {
                // 스파이크 구간
                let min = Int(Double(buyPrice) * 0.9)
                let max = Int(Double(buyPrice) * 6.0)
                return min...max
            } else {
                // 후반 감소
                let min = Int(Double(buyPrice) * 0.4)
                let max = Int(Double(buyPrice) * 0.9)
                return min...max
            }
        }

        return TurnipPrediction(
            pattern: .largeSpikePattern,
            probability: min(probability, 0.9),
            minPrice: Int(Double(buyPrice) * 0.4),
            maxPrice: Int(Double(buyPrice) * 6.0),
            expectedPrices: expectedPrices
        )
    }

    /// 감소형 패턴 분석
    private static func analyzeDecreasing(buyPrice: Int, ratios: [Double?]) -> TurnipPrediction {
        // 감소형: 계속 하락 (0.85 -> 0.4)
        var probability = 0.15 // 기본 확률 15%

        let validRatios = ratios.compactMap { $0 }
        if validRatios.count >= 2 {
            var isDecreasing = true
            for i in 1..<validRatios.count {
                if validRatios[i] > validRatios[i-1] + 0.02 {
                    isDecreasing = false
                    break
                }
            }

            if isDecreasing && validRatios.allSatisfy({ $0 < 1.0 }) {
                probability = min(0.8, 0.3 + Double(validRatios.count) * 0.08)
            } else if !isDecreasing {
                probability = 0.05
            }
        }

        let expectedPrices: [ClosedRange<Int>?] = (0..<12).map { index in
            let maxRatio = max(0.4, 0.9 - Double(index) * 0.04)
            let minRatio = max(0.3, 0.85 - Double(index) * 0.05)
            let min = Int(Double(buyPrice) * minRatio)
            let max = Int(Double(buyPrice) * maxRatio)
            return min...max
        }

        return TurnipPrediction(
            pattern: .decreasing,
            probability: probability,
            minPrice: Int(Double(buyPrice) * 0.3),
            maxPrice: Int(Double(buyPrice) * 0.9),
            expectedPrices: expectedPrices
        )
    }

    /// 4기형 (소폭등) 패턴 분석
    private static func analyzeSmallSpike(buyPrice: Int, ratios: [Double?]) -> TurnipPrediction {
        // 4기형: 감소 -> 소폭 상승 (1.4~2.0배) -> 감소
        var probability = 0.25 // 기본 확률 25%

        let validRatios = ratios.compactMap { $0 }
        if validRatios.count >= 3 {
            var foundSmallSpike = false
            for i in 1..<validRatios.count - 1 {
                if validRatios[i] > 1.0 && validRatios[i] < 2.0 &&
                   validRatios[i] > validRatios[i-1] {
                    foundSmallSpike = true
                    probability = 0.6
                    break
                }
            }

            if !foundSmallSpike && validRatios.allSatisfy({ $0 < 1.0 }) {
                probability = 0.35 // 아직 스파이크 전일 수 있음
            }
        }

        let expectedPrices: [ClosedRange<Int>?] = (0..<12).map { index in
            if index < 6 {
                // 초반 감소
                let min = Int(Double(buyPrice) * max(0.4, 0.9 - Double(index) * 0.08))
                let max = Int(Double(buyPrice) * max(0.5, 0.95 - Double(index) * 0.06))
                return min...max
            } else if index < 9 {
                // 소폭 상승 구간
                let min = Int(Double(buyPrice) * 0.9)
                let max = Int(Double(buyPrice) * 2.0)
                return min...max
            } else {
                // 후반 감소
                let min = Int(Double(buyPrice) * 0.4)
                let max = Int(Double(buyPrice) * 0.9)
                return min...max
            }
        }

        return TurnipPrediction(
            pattern: .smallSpike,
            probability: min(probability, 0.9),
            minPrice: Int(Double(buyPrice) * 0.4),
            maxPrice: Int(Double(buyPrice) * 2.0),
            expectedPrices: expectedPrices
        )
    }

    // MARK: - Helper Methods

    private static func calculateVariance(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDiffs = values.map { ($0 - mean) * ($0 - mean) }
        return squaredDiffs.reduce(0, +) / Double(values.count)
    }
}

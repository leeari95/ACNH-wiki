//
//  TurnipPricePredictor.swift
//  ACNH-wiki
//
//  Created by Ari on 12/28/25.
//

import Foundation

/// 무 가격 예측기 - 확률 기반 접근
/// ac-nh-turnip-prices 프로젝트의 JavaScript 구현을 Swift로 포팅
final class TurnipPricePredictor {

    /// 예측 결과
    struct PredictionResult {
        let minPrices: [Int]  // 14개 (일요일AM, PM, 월~토 AM/PM)
        let maxPrices: [Int]  // 14개
        let pattern: TurnipPricePattern
    }

    private let basePrice: Int
    private let givenPrices: [Int?]  // 14개 (입력된 가격, 없으면 nil)
    private let selectedPattern: TurnipPricePattern?

    init(basePrice: Int, givenPrices: [Int?], selectedPattern: TurnipPricePattern?) {
        self.basePrice = basePrice
        self.givenPrices = givenPrices
        self.selectedPattern = selectedPattern
    }

    /// 가격 예측 실행
    func predict() -> PredictionResult {
        // 패턴별 결과 생성
        let patterns: [TurnipPricePattern] = selectedPattern != nil
            ? [selectedPattern!]
            : [.fluctuating, .largespike, .decreasing, .smallspike]

        var allResults: [PredictionResult] = []

        for pattern in patterns {
            switch pattern {
            case .fluctuating:
                allResults.append(contentsOf: generatePattern0())
            case .largespike:
                allResults.append(contentsOf: generatePattern1())
            case .decreasing:
                allResults.append(contentsOf: generatePattern2())
            case .smallspike:
                allResults.append(contentsOf: generatePattern3())
            case .unknown:
                break
            }
        }

        // 모든 결과의 min/max 통합
        return mergeResults(allResults)
    }

    // MARK: - Pattern Generators

    /// 패턴 0: 변동형 (Fluctuating)
    /// 구조: 상승 - 하락 - 상승 - 하락 - 상승
    private func generatePattern0() -> [PredictionResult] {
        var results: [PredictionResult] = []

        // 길이 조합 시도
        for decPhase1Len in 2...3 {
            let decPhase2Len = 5 - decPhase1Len
            for highPhase1Len in 0...6 {
                let highPhase23Len = 7 - highPhase1Len
                for highPhase3Len in 0...highPhase23Len {
                    let highPhase2Len = highPhase23Len - highPhase3Len

                    if let result = generatePattern0WithLengths(
                        highPhase1Len: highPhase1Len,
                        decPhase1Len: decPhase1Len,
                        highPhase2Len: highPhase2Len,
                        decPhase2Len: decPhase2Len,
                        highPhase3Len: highPhase3Len
                    ) {
                        results.append(result)
                    }
                }
            }
        }

        return results
    }

    private func generatePattern0WithLengths(
        highPhase1Len: Int,
        decPhase1Len: Int,
        highPhase2Len: Int,
        decPhase2Len: Int,
        highPhase3Len: Int
    ) -> PredictionResult? {
        var minPrices = Array(repeating: 0, count: 14)
        var maxPrices = Array(repeating: 0, count: 14)

        // 일요일 (구매가)
        minPrices[0] = basePrice
        maxPrices[0] = basePrice
        minPrices[1] = basePrice
        maxPrices[1] = basePrice

        var work = 2

        // High Phase 1
        for _ in 0..<highPhase1Len {
            if !setPrice(&minPrices, &maxPrices, work, rateMin: 0.9, rateMax: 1.4) {
                return nil
            }
            work += 1
        }

        // Dec Phase 1
        // rate = randfloat(0.8, 0.6)
        // 각 단계마다: rate -= 0.04; rate -= randfloat(0, 0.06)
        // 즉, 매번 0.04~0.1씩 감소
        for i in 0..<decPhase1Len {
            let minRate = max(0.0, 0.6 - Double(i) * 0.1)  // 최소: 0.6에서 시작, 매번 0.1 감소
            let maxRate = max(0.0, 0.8 - Double(i) * 0.04) // 최대: 0.8에서 시작, 매번 0.04 감소
            if !setPrice(&minPrices, &maxPrices, work, rateMin: minRate, rateMax: maxRate) {
                return nil
            }
            work += 1
        }

        // High Phase 2
        for _ in 0..<highPhase2Len {
            if !setPrice(&minPrices, &maxPrices, work, rateMin: 0.9, rateMax: 1.4) {
                return nil
            }
            work += 1
        }

        // Dec Phase 2
        // rate = randfloat(0.8, 0.6)
        // 각 단계마다: rate -= 0.04; rate -= randfloat(0, 0.06)
        for i in 0..<decPhase2Len {
            let minRate = max(0.0, 0.6 - Double(i) * 0.1)  // 최소: 0.6에서 시작, 매번 0.1 감소
            let maxRate = max(0.0, 0.8 - Double(i) * 0.04) // 최대: 0.8에서 시작, 매번 0.04 감소
            if !setPrice(&minPrices, &maxPrices, work, rateMin: minRate, rateMax: maxRate) {
                return nil
            }
            work += 1
        }

        // High Phase 3
        for _ in 0..<highPhase3Len {
            if !setPrice(&minPrices, &maxPrices, work, rateMin: 0.9, rateMax: 1.4) {
                return nil
            }
            work += 1
        }

        return PredictionResult(minPrices: minPrices, maxPrices: maxPrices, pattern: .fluctuating)
    }

    /// 패턴 1: 큰폭 상승 (Large Spike)
    /// 구조: 하락 - 급등 (최대 6배) - 랜덤
    private func generatePattern1() -> [PredictionResult] {
        var results: [PredictionResult] = []

        // 피크 시작 시점: 3~9 (월요일 PM ~ 금요일 PM)
        for peakStart in 3...9 {
            if let result = generatePattern1WithPeak(peakStart: peakStart) {
                results.append(result)
            }
        }

        return results
    }

    private func generatePattern1WithPeak(peakStart: Int) -> PredictionResult? {
        var minPrices = Array(repeating: 0, count: 14)
        var maxPrices = Array(repeating: 0, count: 14)

        // 일요일
        minPrices[0] = basePrice
        maxPrices[0] = basePrice
        minPrices[1] = basePrice
        maxPrices[1] = basePrice

        var work = 2

        // 피크 전 하락
        // rate = randfloat(0.9, 0.85)
        // 각 단계마다: rate -= 0.03; rate -= randfloat(0, 0.02)
        // 즉, 매번 0.03~0.05씩 감소
        for i in 0..<(peakStart - 2) {
            let minRate = max(0.0, 0.85 - Double(i) * 0.05) // 최소: 0.85에서 시작, 매번 0.05 감소
            let maxRate = max(0.0, 0.9 - Double(i) * 0.03)  // 최대: 0.9에서 시작, 매번 0.03 감소
            if !setPrice(&minPrices, &maxPrices, work, rateMin: minRate, rateMax: maxRate) {
                return nil
            }
            work += 1
        }

        // 급등 구간 (5단계)
        let spikeRates: [(Double, Double)] = [
            (0.9, 1.4),   // 1단계
            (1.4, 2.0),   // 2단계
            (2.0, 6.0),   // 3단계 - 피크!
            (1.4, 2.0),   // 4단계
            (0.9, 1.4)    // 5단계
        ]

        for (rateMin, rateMax) in spikeRates {
            if !setPrice(&minPrices, &maxPrices, work, rateMin: rateMin, rateMax: rateMax) {
                return nil
            }
            work += 1
        }

        // 피크 후 랜덤 하락
        while work < 14 {
            if !setPrice(&minPrices, &maxPrices, work, rateMin: 0.4, rateMax: 0.9) {
                return nil
            }
            work += 1
        }

        return PredictionResult(minPrices: minPrices, maxPrices: maxPrices, pattern: .largespike)
    }

    /// 패턴 2: 계속 하락 (Decreasing)
    /// 구조: 지속적 하락
    private func generatePattern2() -> [PredictionResult] {
        var minPrices = Array(repeating: 0, count: 14)
        var maxPrices = Array(repeating: 0, count: 14)

        // 일요일
        minPrices[0] = basePrice
        maxPrices[0] = basePrice
        minPrices[1] = basePrice
        maxPrices[1] = basePrice

        // 지속적 하락 (12단계)
        // rate = randfloat(0.9, 0.85)
        // 각 단계마다: rate -= 0.03; rate -= randfloat(0, 0.02)
        // 즉, 매번 0.03~0.05씩 감소
        for i in 0..<12 {
            let minRate = max(0.0, 0.85 - Double(i) * 0.05) // 최소: 0.85에서 시작, 매번 0.05 감소
            let maxRate = max(0.0, 0.9 - Double(i) * 0.03)  // 최대: 0.9에서 시작, 매번 0.03 감소
            if !setPrice(&minPrices, &maxPrices, i + 2, rateMin: minRate, rateMax: maxRate) {
                return []
            }
        }

        return [PredictionResult(minPrices: minPrices, maxPrices: maxPrices, pattern: .decreasing)]
    }

    /// 패턴 3: 작은폭 상승 (Small Spike)
    /// 구조: 하락 - 작은 상승 (최대 2배) - 하락
    private func generatePattern3() -> [PredictionResult] {
        var results: [PredictionResult] = []

        // 피크 시작 시점: 2~9 (월요일 AM ~ 금요일 PM)
        for peakStart in 2...9 {
            if let result = generatePattern3WithPeak(peakStart: peakStart) {
                results.append(result)
            }
        }

        return results
    }

    private func generatePattern3WithPeak(peakStart: Int) -> PredictionResult? {
        var minPrices = Array(repeating: 0, count: 14)
        var maxPrices = Array(repeating: 0, count: 14)

        // 일요일
        minPrices[0] = basePrice
        maxPrices[0] = basePrice
        minPrices[1] = basePrice
        maxPrices[1] = basePrice

        var work = 2

        // 피크 전 하락
        // rate = randfloat(0.9, 0.4)
        // 각 단계마다: rate -= 0.03; rate -= randfloat(0, 0.02)
        // 즉, 매번 0.03~0.05씩 감소
        for i in 0..<(peakStart - 2) {
            let minRate = max(0.0, 0.4 - Double(i) * 0.05) // 최소: 0.4에서 시작, 매번 0.05 감소
            let maxRate = max(0.0, 0.9 - Double(i) * 0.03) // 최대: 0.9에서 시작, 매번 0.03 감소
            if !setPrice(&minPrices, &maxPrices, work, rateMin: minRate, rateMax: maxRate) {
                return nil
            }
            work += 1
        }

        // 작은 상승 (5단계)
        // 1-2단계: 0.9~1.4
        for _ in 0..<2 {
            if !setPrice(&minPrices, &maxPrices, work, rateMin: 0.9, rateMax: 1.4) {
                return nil
            }
            work += 1
        }

        // 3-5단계: 피크 (1.4~2.0)
        for _ in 0..<3 {
            if !setPrice(&minPrices, &maxPrices, work, rateMin: 1.4, rateMax: 2.0) {
                return nil
            }
            work += 1
        }

        // 피크 후 하락
        // rate = randfloat(0.9, 0.4)
        // 각 단계마다: rate -= 0.03; rate -= randfloat(0, 0.02)
        let remaining = 14 - work
        for i in 0..<remaining {
            let minRate = max(0.0, 0.4 - Double(i) * 0.05) // 최소: 0.4에서 시작, 매번 0.05 감소
            let maxRate = max(0.0, 0.9 - Double(i) * 0.03) // 최대: 0.9에서 시작, 매번 0.03 감소
            if !setPrice(&minPrices, &maxPrices, work, rateMin: minRate, rateMax: maxRate) {
                return nil
            }
            work += 1
        }

        return PredictionResult(minPrices: minPrices, maxPrices: maxPrices, pattern: .smallspike)
    }

    // MARK: - Helper Methods

    /// 가격 설정 및 입력값 검증
    private func setPrice(
        _ minPrices: inout [Int],
        _ maxPrices: inout [Int],
        _ index: Int,
        rateMin: Double,
        rateMax: Double
    ) -> Bool {
        // 입력값이 있으면 그 값 사용
        if let givenPrice = givenPrices[index] {
            minPrices[index] = givenPrice
            maxPrices[index] = givenPrice
        } else {
            // 입력값이 없으면 범위 계산
            minPrices[index] = intCeil(rateMin * Double(basePrice))
            maxPrices[index] = intCeil(rateMax * Double(basePrice))
        }

        return true
    }

    /// 여러 결과를 통합하여 전체 min/max 계산
    private func mergeResults(_ results: [PredictionResult]) -> PredictionResult {
        guard !results.isEmpty else {
            // 결과가 없으면 기본값 반환
            return PredictionResult(
                minPrices: Array(repeating: basePrice, count: 14),
                maxPrices: Array(repeating: basePrice, count: 14),
                pattern: selectedPattern ?? .unknown
            )
        }

        var globalMin = Array(repeating: Int.max, count: 14)
        var globalMax = Array(repeating: 0, count: 14)
        var mostCommonPattern: TurnipPricePattern = .unknown

        // 각 인덱스별로 모든 결과의 min/max 수집
        for i in 0..<14 {
            for result in results {
                globalMin[i] = min(globalMin[i], result.minPrices[i])
                globalMax[i] = max(globalMax[i], result.maxPrices[i])
            }
        }

        // 가장 많이 나타난 패턴 선택
        let patternCounts = results.reduce(into: [:]) { counts, result in
            counts[result.pattern, default: 0] += 1
        }
        mostCommonPattern = patternCounts.max(by: { $0.value < $1.value })?.key ?? .unknown

        return PredictionResult(
            minPrices: globalMin,
            maxPrices: globalMax,
            pattern: mostCommonPattern
        )
    }

    /// intceil 구현 (게임과 동일)
    private func intCeil(_ value: Double) -> Int {
        return Int((value + 0.99999).rounded(.down))
    }
}

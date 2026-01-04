//
//  TurnipPricePredictor.swift
//  ACNH-wiki
//
//  Created by Ari on 12/28/25.
//

import Foundation

// MARK: - Probability Density Function

/// Rate의 확률 밀도 함수 (PDF)
/// JavaScript 구현과 동일한 확률 기반 예측을 위한 클래스
final class PDF {
    /// 값의 시작점 (포함)
    private(set) var valueStart: Int
    /// 값의 끝점 (제외)
    private(set) var valueEnd: Int
    /// 각 정수 범위의 확률 배열
    private(set) var prob: [Double]

    /// PDF 초기화
    /// - Parameters:
    ///   - start: 시작 값 (실수 가능)
    ///   - end: 끝 값 (실수 가능)
    ///   - uniform: true면 균등 분포로 초기화
    init(start: Double, end: Double, uniform: Bool = true) {
        self.valueStart = Int(floor(start))
        self.valueEnd = Int(ceil(end))
        let range = (start, end)
        let totalLength = end - start

        self.prob = Array(repeating: 0.0, count: valueEnd - valueStart)

        if uniform {
            for index in 0..<prob.count {
                let rangeOfI = rangeOf(idx: index)
                let intersectLen = rangeIntersectLength(rangeOfI, range)
                prob[index] = intersectLen / totalLength
            }
        }
    }

    /// 주어진 인덱스의 범위 계산
    /// - Parameter idx: prob 배열의 인덱스
    /// - Returns: [idx, idx+1) 범위
    private func rangeOf(idx: Int) -> (Double, Double) {
        let start = Double(valueStart + idx)
        let end = Double(valueStart + idx + 1)
        return (start, end)
    }

    /// 최소값 반환
    func minValue() -> Int {
        return valueStart
    }

    /// 최대값 반환
    func maxValue() -> Int {
        return valueEnd
    }

    /// 확률 정규화 (합이 1이 되도록)
    /// - Returns: 정규화 전 총 확률
    @discardableResult
    func normalize() -> Double {
        let totalProbability = floatSum(prob)
        guard totalProbability > 0 else {
            return 0
        }
        for index in 0..<prob.count {
            prob[index] /= totalProbability
        }
        return totalProbability
    }

    /// PDF를 특정 범위로 제한
    /// - Parameter range: 제한할 범위 (min, max)
    /// - Returns: 이 범위에 속할 확률
    func rangeLimit(_ range: (min: Double, max: Double)) -> Double {
        var start = max(range.min, Double(minValue()))
        var end = min(range.max, Double(maxValue()))

        if start >= end {
            // 무효한 범위 - PDF를 비움
            valueStart = 0
            valueEnd = 0
            prob = []
            return 0
        }

        start = floor(start)
        end = ceil(end)

        let startIdx = Int(start) - valueStart
        let endIdx = Int(end) - valueStart

        for index in startIdx..<endIdx {
            let rangeOfI = rangeOf(idx: index)
            let intersectLen = rangeIntersectLength(rangeOfI, range)
            prob[index] *= intersectLen
        }

        prob = Array(prob[startIdx..<endIdx])
        valueStart = Int(start)
        valueEnd = Int(end)

        return normalize()
    }

    /// PDF를 decay (감소) - 균등 분포 [decayMin, decayMax]만큼 빼기
    /// - Parameters:
    ///   - decayMin: 최소 감소량
    ///   - decayMax: 최대 감소량
    func decay(decayMin: Int, decayMax: Int) {
        let rateDecayMin = decayMin
        let rateDecayMax = decayMax

        // Prefix sum 계산
        let prefix = prefixFloatSum(prob)
        let maxX = prob.count
        let maxY = rateDecayMax - rateDecayMin

        var newProb = Array(repeating: 0.0, count: prob.count + maxY)

        for index in 0..<newProb.count {
            let left = max(0, index - maxY)
            let right = min(maxX - 1, index)

            // Prefix sum을 사용하여 범위 합 계산
            var numbersToSum: [Double] = [
                prefix[right + 1].sum,
                prefix[right + 1].error,
                -prefix[left].sum,
                -prefix[left].error
            ]

            // 엔드포인트 보정
            if left == index - maxY {
                numbersToSum.append(-prob[left] / 2)
            }
            if right == index {
                numbersToSum.append(-prob[right] / 2)
            }

            newProb[index] = floatSum(numbersToSum) / Double(maxY)
        }

        prob = newProb
        valueStart -= rateDecayMax
        valueEnd -= rateDecayMin
    }

    // MARK: - Helper Functions

    /// 두 범위의 교집합 길이 계산
    private func rangeIntersectLength(_ range1: (Double, Double), _ range2: (Double, Double)) -> Double {
        if range1.0 > range2.1 || range1.1 < range2.0 {
            return 0
        }
        let intersectStart = max(range1.0, range2.0)
        let intersectEnd = min(range1.1, range2.1)
        return intersectEnd - intersectStart
    }

    /// Kahan-Babuska 알고리즘을 사용한 정확한 부동소수점 합계
    private func floatSum(_ input: [Double]) -> Double {
        var sum = 0.0
        var count = 0.0  // "lost bits" of sum

        for current in input {
            let tempSum = sum + current
            if abs(sum) >= abs(current) {
                count += (sum - tempSum) + current
            } else {
                count += (current - tempSum) + sum
            }
            sum = tempSum
        }

        return sum + count
    }

    /// Prefix sum with error tracking
    private func prefixFloatSum(_ input: [Double]) -> [(sum: Double, error: Double)] {
        var prefixSum: [(sum: Double, error: Double)] = [(0, 0)]
        var sum = 0.0
        var count = 0.0

        for current in input {
            let tempSum = sum + current
            if abs(sum) >= abs(current) {
                count += (sum - tempSum) + current
            } else {
                count += (current - tempSum) + sum
            }
            sum = tempSum
            prefixSum.append((sum, count))
        }

        return prefixSum
    }
}

// MARK: - Turnip Price Predictor

/// 무 가격 예측기 - 확률 기반 접근
/// ac-nh-turnip-prices 프로젝트의 JavaScript 구현을 Swift로 포팅
final class TurnipPricePredictor {

    /// 예측 결과
    struct PredictionResult {
        let minPrices: [Int]  // 14개 (일요일AM, PM, 월~토 AM/PM)
        let maxPrices: [Int]  // 14개
        let pattern: TurnipPricePattern
    }

    // MARK: - Constants

    /// Rate를 정수로 다루기 위한 승수 (JavaScript와 동일)
    private static let rateMultiplier = 10000

    /// 입력값 검증 시 허용 오차 (JavaScript처럼 동적으로 증가)
    private var fudgeFactor = 0

    // MARK: - Properties

    private let basePrice: Int
    private let givenPrices: [Int?]  // 14개 (입력된 가격, 없으면 nil)
    private let selectedPattern: TurnipPricePattern?
    private let isFirstBuy: Bool

    init(basePrice: Int, givenPrices: [Int?], selectedPattern: TurnipPricePattern?, isFirstBuy: Bool) {
        self.basePrice = basePrice
        self.givenPrices = givenPrices
        self.selectedPattern = selectedPattern
        self.isFirstBuy = isFirstBuy
    }

    /// 가격 예측 실행
    func predict() -> PredictionResult {
        // JavaScript처럼 fudge_factor를 0부터 증가시키며 시도
        var allResults: [PredictionResult] = []

        for factor in 0...5 {
            self.fudgeFactor = factor

            // 패턴별 결과 생성
            // 첫 구매인 경우 패턴 3 (Small Spike)만 생성 (ac-nh-turnip-prices와 동일)
            let patterns: [TurnipPricePattern]
            if isFirstBuy {
                patterns = [.smallspike]
            } else if selectedPattern != nil {
                patterns = [selectedPattern!]
            } else {
                patterns = [.fluctuating, .largespike, .decreasing, .smallspike]
            }

            var factorResults: [PredictionResult] = []

            for pattern in patterns {
                let patternResults: [PredictionResult]
                switch pattern {
                case .fluctuating:
                    patternResults = generatePattern0()
                case .largespike:
                    patternResults = generatePattern1()
                case .decreasing:
                    patternResults = generatePattern2()
                case .smallspike:
                    patternResults = generatePattern3()
                case .unknown:
                    patternResults = []
                }
                factorResults.append(contentsOf: patternResults)
            }

            if !factorResults.isEmpty {
                allResults = factorResults
                break  // JavaScript처럼 결과가 나오면 중단
            }
        }

        // 모든 결과의 min/max 통합
        let finalResult = mergeResults(allResults)
        return finalResult
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
                for highPhase3Len in 0..<highPhase23Len {  // JavaScript와 동일하게 < 사용
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

        var probability = 1.0

        // High Phase 1
        if !generateIndividualRandomPrice(
            minPrices: &minPrices,
            maxPrices: &maxPrices,
            start: work,
            length: highPhase1Len,
            rateMin: 0.9,
            rateMax: 1.4
        ) {
            return nil
        }
        work += highPhase1Len

        // Dec Phase 1
        probability *= generateDecreasingRandomPrice(
            minPrices: &minPrices,
            maxPrices: &maxPrices,
            start: work,
            length: decPhase1Len,
            startRateMin: 0.6,
            startRateMax: 0.8,
            rateDecayMin: 0.04,
            rateDecayMax: 0.1
        )
        if probability == 0 {
            return nil
        }
        work += decPhase1Len

        // High Phase 2
        if !generateIndividualRandomPrice(
            minPrices: &minPrices,
            maxPrices: &maxPrices,
            start: work,
            length: highPhase2Len,
            rateMin: 0.9,
            rateMax: 1.4
        ) {
            return nil
        }
        work += highPhase2Len

        // Dec Phase 2
        probability *= generateDecreasingRandomPrice(
            minPrices: &minPrices,
            maxPrices: &maxPrices,
            start: work,
            length: decPhase2Len,
            startRateMin: 0.6,
            startRateMax: 0.8,
            rateDecayMin: 0.04,
            rateDecayMax: 0.1
        )
        if probability == 0 {
            return nil
        }
        work += decPhase2Len

        // High Phase 3
        if !generateIndividualRandomPrice(
            minPrices: &minPrices,
            maxPrices: &maxPrices,
            start: work,
            length: highPhase3Len,
            rateMin: 0.9,
            rateMax: 1.4
        ) {
            return nil
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
        var probability = 1.0

        // 피크 전 하락
        probability *= generateDecreasingRandomPrice(
            minPrices: &minPrices,
            maxPrices: &maxPrices,
            start: work,
            length: peakStart - 2,
            startRateMin: 0.85,
            startRateMax: 0.9,
            rateDecayMin: 0.03,
            rateDecayMax: 0.05
        )
        if probability == 0 {
            return nil
        }
        work = peakStart

        // 급등 구간 (5단계)
        let minRandoms: [Double] = [0.9, 1.4, 2.0, 1.4, 0.9]
        let maxRandoms: [Double] = [1.4, 2.0, 6.0, 2.0, 1.4]

        for index in 0..<5 {
            if work >= 14 {
                break
            }

            if !generateIndividualRandomPrice(
                minPrices: &minPrices,
                maxPrices: &maxPrices,
                start: work,
                length: 1,
                rateMin: minRandoms[index],
                rateMax: maxRandoms[index]
            ) {
                return nil
            }
            work += 1
        }

        // 피크 후 랜덤 하락
        if work < 14 {
            if !generateIndividualRandomPrice(
                minPrices: &minPrices,
                maxPrices: &maxPrices,
                start: work,
                length: 14 - work,
                rateMin: 0.4,
                rateMax: 0.9
            ) {
                return nil
            }
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
        let probability = generateDecreasingRandomPrice(
            minPrices: &minPrices,
            maxPrices: &maxPrices,
            start: 2,
            length: 12,
            startRateMin: 0.85,
            startRateMax: 0.9,
            rateDecayMin: 0.03,
            rateDecayMax: 0.05
        )

        if probability == 0 {
            return []
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
        var probability = 1.0

        // 피크 전 하락
        probability *= generateDecreasingRandomPrice(
            minPrices: &minPrices,
            maxPrices: &maxPrices,
            start: work,
            length: peakStart - 2,
            startRateMin: 0.4,
            startRateMax: 0.9,
            rateDecayMin: 0.03,
            rateDecayMax: 0.05
        )
        if probability == 0 {
            return nil
        }
        work = peakStart

        // 작은 상승 (5단계)
        // 1-2단계: 0.9~1.4
        if !generateIndividualRandomPrice(
            minPrices: &minPrices,
            maxPrices: &maxPrices,
            start: work,
            length: 2,
            rateMin: 0.9,
            rateMax: 1.4
        ) {
            return nil
        }
        work += 2

        // 3-5단계: 피크 (1.4~2.0) - generate_peak_price 사용
        if !generatePeakPrice(
            minPrices: &minPrices,
            maxPrices: &maxPrices,
            start: work,
            rateMin: 1.4,
            rateMax: 2.0
        ) {
            return nil
        }
        work += 3

        // 피크 후 하락
        if work < 14 {
            probability *= generateDecreasingRandomPrice(
                minPrices: &minPrices,
                maxPrices: &maxPrices,
                start: work,
                length: 14 - work,
                startRateMin: 0.4,
                startRateMax: 0.9,
                rateDecayMin: 0.03,
                rateDecayMax: 0.05
            )
            if probability == 0 {
                return nil
            }
        }

        return PredictionResult(minPrices: minPrices, maxPrices: maxPrices, pattern: .smallspike)
    }

    // MARK: - Helper Methods

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
        for index in 0..<14 {
            for result in results {
                globalMin[index] = min(globalMin[index], result.minPrices[index])
                globalMax[index] = max(globalMax[index], result.maxPrices[index])
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

    // MARK: - Utility Functions (JavaScript 호환)

    /// rate를 사용하여 가격 계산 (rateMultiplier 적용)
    private func getPrice(rate: Int, basePrice: Int) -> Int {
        return intCeil(Double(rate) * Double(basePrice) / Double(Self.rateMultiplier))
    }

    /// 주어진 가격으로부터 최소 rate 역산
    private func minimumRateFromGivenAndBase(givenPrice: Int, buyPrice: Int) -> Int {
        return Self.rateMultiplier * (givenPrice - 1) / buyPrice
    }

    /// 주어진 가격으로부터 최대 rate 역산
    private func maximumRateFromGivenAndBase(givenPrice: Int, buyPrice: Int) -> Int {
        return Self.rateMultiplier * givenPrice / buyPrice
    }

    /// 주어진 가격으로부터 가능한 rate 범위 계산
    private func rateRangeFromGivenAndBase(givenPrice: Int, buyPrice: Int) -> (min: Int, max: Int) {
        return (
            min: minimumRateFromGivenAndBase(givenPrice: givenPrice, buyPrice: buyPrice),
            max: maximumRateFromGivenAndBase(givenPrice: givenPrice, buyPrice: buyPrice)
        )
    }

    /// 두 범위의 교집합 계산
    private func rangeIntersect(_ range1: (min: Int, max: Int), _ range2: (min: Int, max: Int)) -> (min: Int, max: Int)? {
        if range1.min > range2.max || range1.max < range2.min {
            return nil
        }
        return (min: max(range1.min, range2.min), max: min(range1.max, range2.max))
    }

    /// 범위의 길이 계산
    private func rangeLength(_ range: (min: Int, max: Int)) -> Int {
        return range.max - range.min
    }

    /// 값을 min~max 범위로 제한
    private func clamp(_ value: Int, min: Int, max: Int) -> Int {
        return Swift.max(min, Swift.min(value, max))
    }

    // MARK: - Pattern Generation Helper Methods

    /// 개별 랜덤 가격 생성 (JavaScript의 generate_individual_random_price)
    /// - Returns: 조건부 확률 (0이면 패턴 불가능)
    private func generateIndividualRandomPrice(
        minPrices: inout [Int],
        maxPrices: inout [Int],
        start: Int,
        length: Int,
        rateMin: Double,
        rateMax: Double
    ) -> Bool {
        let rateMinInt = Int(rateMin * Double(Self.rateMultiplier))
        let rateMaxInt = Int(rateMax * Double(Self.rateMultiplier))

        let rateRange = (min: rateMinInt, max: rateMaxInt)

        for index in start..<(start + length) {
            var minPred = getPrice(rate: rateMinInt, basePrice: basePrice)
            var maxPred = getPrice(rate: rateMaxInt, basePrice: basePrice)

            if let givenPrice = givenPrices[index] {
                // 입력값이 예측 범위를 벗어나면 이 패턴은 불가능
                if givenPrice < minPred - fudgeFactor || givenPrice > maxPred + fudgeFactor {
                    return false
                }

                // 입력값에서 가능한 rate 범위 역산
                let clampedPrice = clamp(givenPrice, min: minPred, max: maxPred)
                let realRateRange = rateRangeFromGivenAndBase(givenPrice: clampedPrice, buyPrice: basePrice)

                // 교집합이 없으면 불가능
                guard rangeIntersect(rateRange, realRateRange) != nil else {
                    return false
                }

                minPred = givenPrice
                maxPred = givenPrice
            }

            minPrices[index] = minPred
            maxPrices[index] = maxPred
        }

        return true
    }

    /// 하락 랜덤 가격 생성 (JavaScript의 generate_decreasing_random_price)
    /// - Returns: 조건부 확률 (0이면 패턴 불가능)
    private func generateDecreasingRandomPrice(
        minPrices: inout [Int],
        maxPrices: inout [Int],
        start: Int,
        length: Int,
        startRateMin: Double,
        startRateMax: Double,
        rateDecayMin: Double,
        rateDecayMax: Double
    ) -> Double {
        let rateMin = startRateMin * Double(Self.rateMultiplier)
        let rateMax = startRateMax * Double(Self.rateMultiplier)
        let decayMin = Int(rateDecayMin * Double(Self.rateMultiplier))
        let decayMax = Int(rateDecayMax * Double(Self.rateMultiplier))

        let buyPrice = basePrice
        let ratePdf = PDF(start: rateMin, end: rateMax)
        var prob = 1.0

        for index in start..<(start + length) {
            var minPred = getPrice(rate: ratePdf.minValue(), basePrice: buyPrice)
            var maxPred = getPrice(rate: ratePdf.maxValue(), basePrice: buyPrice)

            if let givenPrice = givenPrices[index] {
                if givenPrice < minPred - fudgeFactor || givenPrice > maxPred + fudgeFactor {
                    return 0  // 패턴 불가능
                }

                // 입력값으로부터 가능한 rate 범위 역산
                let clampedPrice = clamp(givenPrice, min: minPred, max: maxPred)
                let realRateRange = rateRangeFromGivenAndBase(givenPrice: clampedPrice, buyPrice: buyPrice)

                // PDF 범위를 제한하고 확률 곱하기
                let rangeProb = ratePdf.rangeLimit((
                    min: Double(realRateRange.min),
                    max: Double(realRateRange.max)
                ))
                prob *= rangeProb

                if prob == 0 {
                    return 0
                }

                minPred = givenPrice
                maxPred = givenPrice
            }

            minPrices[index] = minPred
            maxPrices[index] = maxPred

            // 다음 단계로 decay
            ratePdf.decay(decayMin: decayMin, decayMax: decayMax)
        }

        return prob
    }

    /// 피크 가격 생성 (JavaScript의 generate_peak_price)
    /// - Returns: 조건부 확률 (0이면 패턴 불가능)
    private func generatePeakPrice(
        minPrices: inout [Int],
        maxPrices: inout [Int],
        start: Int,
        rateMin: Double,
        rateMax: Double
    ) -> Bool {
        /*
        이 메서드는 다음 패턴을 생성:
        sellPrices[work++] = intceil(randfloat(rate_min, rate) * basePrice) - 1;
        sellPrices[work++] = intceil(rate * basePrice);
        sellPrices[work++] = intceil(randfloat(rate_min, rate) * basePrice) - 1;
        */

        let rateMinInt = Int(rateMin * Double(Self.rateMultiplier))
        let rateMaxInt = Int(rateMax * Double(Self.rateMultiplier))

        // 중간값 (피크)
        var minPred = getPrice(rate: rateMinInt, basePrice: basePrice)
        var maxPred = getPrice(rate: rateMaxInt, basePrice: basePrice)

        if let givenPrice = givenPrices[start + 1] {
            if givenPrice < minPred - fudgeFactor || givenPrice > maxPred + fudgeFactor {
                return false
            }
            minPred = givenPrice
            maxPred = givenPrice
        }

        minPrices[start + 1] = minPred
        maxPrices[start + 1] = maxPred

        // 왼쪽과 오른쪽 (피크보다 1 낮음)
        for offset in [0, 2] {
            let index = start + offset
            var minPred = getPrice(rate: rateMinInt, basePrice: basePrice) - 1
            var maxPred = getPrice(rate: rateMaxInt, basePrice: basePrice) - 1

            if let givenPrice = givenPrices[index] {
                if givenPrice < minPred - fudgeFactor || givenPrice > maxPred + fudgeFactor {
                    return false
                }
                minPred = givenPrice
                maxPred = givenPrice
            }

            minPrices[index] = minPred
            maxPrices[index] = maxPred
        }

        return true
    }
}

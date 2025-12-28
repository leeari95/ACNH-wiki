//
//  TurnipPricesReactor.swift
//  ACNH-wiki
//
//  Created by Ari on 12/17/25.
//

import Foundation
import ReactorKit

final class TurnipPricesReactor: Reactor {

    enum Action {
        case fetch
        case selectPattern(TurnipPricePattern)
        case updateSundayPrice(String)
        case updatePrice(day: DayOfWeek, period: Period, price: String)
        case calculate
    }

    enum Mutation {
        case setPattern(TurnipPricePattern)
        case setSundayPrice(String)
        case setPrice(day: DayOfWeek, period: Period, price: String)
        case setCalculatedResult(basePrice: Int, pattern: TurnipPricePattern, prices: [DayOfWeek: [Period: Int]])
    }

    struct State {
        var selectedPattern: TurnipPricePattern = .unknown
        var sundayPrice: String = ""
        var prices: [DayOfWeek: [Period: String]] = [
            .monday: [.am: "", .pm: ""],
            .tuesday: [.am: "", .pm: ""],
            .wednesday: [.am: "", .pm: ""],
            .thursday: [.am: "", .pm: ""],
            .friday: [.am: "", .pm: ""],
            .saturday: [.am: "", .pm: ""]
        ]
        var calculatedPrices: [DayOfWeek: [Period: Int]] = [:]
        var calculatedBasePrice: Int?
        var calculatedPattern: TurnipPricePattern?
    }

    enum DayOfWeek: CaseIterable {
        case monday, tuesday, wednesday, thursday, friday, saturday
    }

    enum Period {
        case am, pm
    }

    struct UserInput {
        let day: DayOfWeek
        let period: Period
        let price: Int
    }

    struct PredictionResult {
        let pattern: TurnipPricePattern
        let avgPrices: [DayOfWeek: [Period: Int]]
        let minPrices: [DayOfWeek: [Period: Int]]
        let maxPrices: [DayOfWeek: [Period: Int]]
    }

    let initialState: State
    var coordinator: TurnipPricesCoordinator?

    init(coordinator: TurnipPricesCoordinator, state: State = State()) {
        self.coordinator = coordinator
        self.initialState = state
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetch:
            return .empty()

        case .selectPattern(let pattern):
            return .just(.setPattern(pattern))

        case .updateSundayPrice(let price):
            return .just(.setSundayPrice(price))

        case .updatePrice(let day, let period, let price):
            return .just(.setPrice(day: day, period: period, price: price))

        case .calculate:
            return calculatePrices()
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setPattern(let pattern):
            newState.selectedPattern = pattern

        case .setSundayPrice(let price):
            newState.sundayPrice = price

        case .setPrice(let day, let period, let price):
            newState.prices[day]?[period] = price

        case .setCalculatedResult(let basePrice, let pattern, let prices):
            newState.calculatedBasePrice = basePrice
            newState.calculatedPattern = pattern
            newState.calculatedPrices = prices
        }

        return newState
    }

    // MARK: - Private Methods

    private func calculatePrices() -> Observable<Mutation> {
        // 사용자가 입력한 일요일 구매가
        let userBasePrice = Int(currentState.sundayPrice)
        let basePrice = userBasePrice ?? 100

        // 사용자가 입력한 가격들 수집
        var userInputs: [UserInput] = []
        for day in DayOfWeek.allCases {
            if let amPrice = Int(currentState.prices[day]?[.am] ?? ""), amPrice > 0 {
                userInputs.append(UserInput(day: day, period: .am, price: amPrice))
            }
            if let pmPrice = Int(currentState.prices[day]?[.pm] ?? ""), pmPrice > 0 {
                userInputs.append(UserInput(day: day, period: .pm, price: pmPrice))
            }
        }

        // 입력값과 일치하는 패턴 찾기
        let result = findMatchingPattern(
            basePrice: basePrice,
            userInputs: userInputs,
            selectedPattern: currentState.selectedPattern
        )

        // 입력값이 있는 요일은 입력값으로 고정
        var finalMinPrices = result.minPrices
        var finalMaxPrices = result.maxPrices

        for input in userInputs {
            finalMinPrices[input.day]?[input.period] = input.price
            finalMaxPrices[input.day]?[input.period] = input.price
        }

        // Coordinator를 통해 결과 화면 표시
        coordinator?.transition(for: .showResult(
            basePrice: basePrice,
            pattern: result.pattern,
            minPrices: finalMinPrices,
            maxPrices: finalMaxPrices
        ))

        return .just(.setCalculatedResult(
            basePrice: basePrice,
            pattern: result.pattern,
            prices: result.avgPrices
        ))
    }

    /// 입력된 가격과 일치하는 모든 패턴을 찾아서 min/max 계산
    private func findMatchingPattern(
        basePrice: Int,
        userInputs: [UserInput],
        selectedPattern: TurnipPricePattern
    ) -> PredictionResult {
        // 사용자 입력을 배열 형태로 변환 (14개 요소)
        let givenPrices = convertToGivenPricesArray(userInputs: userInputs)

        // TurnipPricePredictor를 사용하여 예측
        let predictor = TurnipPricePredictor(
            basePrice: basePrice,
            givenPrices: givenPrices,
            selectedPattern: selectedPattern != .unknown ? selectedPattern : nil
        )

        let result = predictor.predict()

        // 예측 결과를 DayOfWeek/Period 형태로 변환
        return convertToReactorResult(
            minPrices: result.minPrices,
            maxPrices: result.maxPrices,
            pattern: result.pattern
        )
    }

    /// 사용자 입력을 14개 요소의 배열로 변환
    /// 인덱스: [일요일AM(0), 일요일PM(1), 월AM(2), 월PM(3), ..., 토PM(13)]
    private func convertToGivenPricesArray(userInputs: [UserInput]) -> [Int?] {
        var givenPrices = Array(repeating: nil as Int?, count: 14)

        // 일요일 (0, 1)은 구매가이므로 항상 nil
        // 월~토 (2~13)만 입력값 적용
        for input in userInputs {
            let index = dayPeriodToIndex(day: input.day, period: input.period)
            givenPrices[index] = input.price
        }

        return givenPrices
    }

    /// 예측 결과 배열을 DayOfWeek/Period 형태로 변환
    private func convertToReactorResult(
        minPrices: [Int],
        maxPrices: [Int],
        pattern: TurnipPricePattern
    ) -> PredictionResult {
        var minDict: [DayOfWeek: [Period: Int]] = [:]
        var maxDict: [DayOfWeek: [Period: Int]] = [:]
        var avgDict: [DayOfWeek: [Period: Int]] = [:]

        for day in DayOfWeek.allCases {
            let amIndex = dayPeriodToIndex(day: day, period: .am)
            let pmIndex = dayPeriodToIndex(day: day, period: .pm)

            minDict[day] = [
                .am: minPrices[amIndex],
                .pm: minPrices[pmIndex]
            ]

            maxDict[day] = [
                .am: maxPrices[amIndex],
                .pm: maxPrices[pmIndex]
            ]

            avgDict[day] = [
                .am: (minPrices[amIndex] + maxPrices[amIndex]) / 2,
                .pm: (minPrices[pmIndex] + maxPrices[pmIndex]) / 2
            ]
        }

        return PredictionResult(
            pattern: pattern,
            avgPrices: avgDict,
            minPrices: minDict,
            maxPrices: maxDict
        )
    }

    /// DayOfWeek와 Period를 배열 인덱스로 변환
    private func dayPeriodToIndex(day: DayOfWeek, period: Period) -> Int {
        let dayOffset: Int
        switch day {
        case .monday: dayOffset = 0
        case .tuesday: dayOffset = 1
        case .wednesday: dayOffset = 2
        case .thursday: dayOffset = 3
        case .friday: dayOffset = 4
        case .saturday: dayOffset = 5
        }

        let baseIndex = 2 + (dayOffset * 2)  // 일요일 2개(0,1) 이후부터 시작
        return baseIndex + (period == .pm ? 1 : 0)
    }
}

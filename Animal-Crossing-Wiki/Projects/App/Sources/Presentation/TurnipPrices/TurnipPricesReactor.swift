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

    let initialState: State
    var coordinator: TurnipPricesCoordinator?
    private let calculator: TurnipPriceCalculator

    init(coordinator: TurnipPricesCoordinator, state: State = State(), calculator: TurnipPriceCalculator = TurnipPriceCalculator()) {
        self.coordinator = coordinator
        self.initialState = state
        self.calculator = calculator
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
        // 현재 상태에서 선택된 패턴으로 계산
        let previousPattern = currentState.selectedPattern

        // 계산 실행
        calculator.calculate(previousPattern: previousPattern != .unknown ? previousPattern : nil)

        // 계산 결과를 Dictionary로 변환
        var calculatedPrices: [DayOfWeek: [Period: Int]] = [:]
        for day in DayOfWeek.allCases {
            calculatedPrices[day] = [
                .am: calculator.getPrice(day: day, period: .am),
                .pm: calculator.getPrice(day: day, period: .pm)
            ]
        }

        // Coordinator를 통해 결과 화면 표시
        coordinator?.transition(for: .showResult(
            basePrice: calculator.basePrice,
            pattern: calculator.currentPattern,
            prices: calculatedPrices
        ))

        return .just(.setCalculatedResult(
            basePrice: calculator.basePrice,
            pattern: calculator.currentPattern,
            prices: calculatedPrices
        ))
    }
}

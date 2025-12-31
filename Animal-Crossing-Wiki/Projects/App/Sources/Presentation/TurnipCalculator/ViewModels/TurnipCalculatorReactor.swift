//
//  TurnipCalculatorReactor.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation
import ReactorKit
import RxSwift

final class TurnipCalculatorReactor: Reactor {

    enum Action {
        case viewDidLoad
        case updateBuyPrice(String?)
        case updatePrice(index: Int, price: String?)
        case clearAll
        case save
    }

    enum Mutation {
        case setTurnipPrice(TurnipPrice)
        case setPredictions([TurnipPrediction])
        case setExpectedRange(min: Int, max: Int)
        case setLoading(Bool)
        case setError(String?)
    }

    struct State {
        var turnipPrice: TurnipPrice
        var predictions: [TurnipPrediction] = []
        var expectedMinPrice: Int = 0
        var expectedMaxPrice: Int = 0
        var isLoading: Bool = false
        var errorMessage: String?

        init(turnipPrice: TurnipPrice = TurnipPrice()) {
            self.turnipPrice = turnipPrice
        }
    }

    let initialState: State
    weak var coordinator: DashboardCoordinator?
    private let storage: TurnipPriceStorage

    init(
        coordinator: DashboardCoordinator? = nil,
        storage: TurnipPriceStorage = CoreDataTurnipPriceStorage(),
        turnipPrice: TurnipPrice? = nil
    ) {
        self.coordinator = coordinator
        self.storage = storage
        self.initialState = State(turnipPrice: turnipPrice ?? TurnipPrice())
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return loadCurrentWeekPrice()

        case .updateBuyPrice(let priceString):
            let price = parsePrice(priceString)
            let updatedTurnip = currentState.turnipPrice.updateBuyPrice(price)
            return updatePriceAndPredict(updatedTurnip)

        case .updatePrice(let index, let priceString):
            let price = parsePrice(priceString)
            let updatedTurnip = currentState.turnipPrice.updatePrice(at: index, price: price)
            return updatePriceAndPredict(updatedTurnip)

        case .clearAll:
            let newTurnip = TurnipPrice(
                id: currentState.turnipPrice.id,
                weekStartDate: Date().startOfWeek
            )
            // 저장소에 초기화된 데이터를 반영하고 UI 업데이트
            return storage.updatePrice(newTurnip)
                .asObservable()
                .flatMap { _ -> Observable<Mutation> in
                    return Observable.concat([
                        Observable.just(Mutation.setTurnipPrice(newTurnip)),
                        Observable.just(Mutation.setPredictions([])),
                        Observable.just(Mutation.setExpectedRange(min: 0, max: 0))
                    ])
                }
                .catch { _ in
                    // 저장 실패해도 UI는 초기화
                    return Observable.concat([
                        Observable.just(Mutation.setTurnipPrice(newTurnip)),
                        Observable.just(Mutation.setPredictions([])),
                        Observable.just(Mutation.setExpectedRange(min: 0, max: 0))
                    ])
                }

        case .save:
            return saveCurrentPrice()
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setTurnipPrice(let turnipPrice):
            newState.turnipPrice = turnipPrice

        case .setPredictions(let predictions):
            newState.predictions = predictions

        case .setExpectedRange(let min, let max):
            newState.expectedMinPrice = min
            newState.expectedMaxPrice = max

        case .setLoading(let isLoading):
            newState.isLoading = isLoading

        case .setError(let message):
            newState.errorMessage = message
        }

        return newState
    }

    // MARK: - Private Methods

    private func loadCurrentWeekPrice() -> Observable<Mutation> {
        return Observable.concat([
            Observable.just(Mutation.setLoading(true)),
            storage.fetchCurrentWeekPrice()
                .asObservable()
                .flatMap { [weak self] turnipPrice -> Observable<Mutation> in
                    guard let self = self else { return .empty() }
                    let price = turnipPrice ?? TurnipPrice(weekStartDate: Date().startOfWeek)

                    var mutations: [Observable<Mutation>] = [
                        Observable.just(Mutation.setTurnipPrice(price)),
                        Observable.just(Mutation.setLoading(false))
                    ]

                    if price.buyPrice != nil {
                        let predictions = TurnipPricePredictor.predict(turnipPrice: price)
                        mutations.insert(Observable.just(Mutation.setPredictions(predictions)), at: 1)

                        if let range = TurnipPricePredictor.getExpectedPriceRange(turnipPrice: price) {
                            mutations.insert(
                                Observable.just(Mutation.setExpectedRange(min: range.min, max: range.max)),
                                at: 2
                            )
                        }
                    }

                    return Observable.concat(mutations)
                }
                .catch { error in
                    return Observable.concat([
                        Observable.just(Mutation.setError(error.localizedDescription)),
                        Observable.just(Mutation.setLoading(false))
                    ])
                }
        ])
    }

    private func updatePriceAndPredict(_ turnipPrice: TurnipPrice) -> Observable<Mutation> {
        let predictions = TurnipPricePredictor.predict(turnipPrice: turnipPrice)
        let range = TurnipPricePredictor.getExpectedPriceRange(turnipPrice: turnipPrice)

        // 먼저 UI 업데이트 후 백그라운드에서 저장
        let uiMutations = Observable.concat([
            Observable.just(Mutation.setTurnipPrice(turnipPrice)),
            Observable.just(Mutation.setPredictions(predictions)),
            Observable.just(Mutation.setExpectedRange(min: range?.min ?? 0, max: range?.max ?? 0))
        ])

        // 저장은 UI 업데이트와 별도로 수행 (fire-and-forget이지만 구독은 함)
        let saveMutation = storage.updatePrice(turnipPrice)
            .asObservable()
            .flatMap { _ -> Observable<Mutation> in .empty() }
            .catch { _ -> Observable<Mutation> in .empty() }

        return Observable.merge(uiMutations, saveMutation)
    }

    private func saveCurrentPrice() -> Observable<Mutation> {
        let turnipPrice = currentState.turnipPrice

        return Observable.concat([
            Observable.just(Mutation.setLoading(true)),
            storage.savePrice(turnipPrice)
                .asObservable()
                .flatMap { savedPrice -> Observable<Mutation> in
                    return Observable.concat([
                        Observable.just(Mutation.setTurnipPrice(savedPrice)),
                        Observable.just(Mutation.setLoading(false))
                    ])
                }
                .catch { error in
                    return Observable.concat([
                        Observable.just(Mutation.setError(error.localizedDescription)),
                        Observable.just(Mutation.setLoading(false))
                    ])
                }
        ])
    }

    private func parsePrice(_ priceString: String?) -> Int? {
        guard let string = priceString, !string.isEmpty else { return nil }
        return Int(string)
    }
}

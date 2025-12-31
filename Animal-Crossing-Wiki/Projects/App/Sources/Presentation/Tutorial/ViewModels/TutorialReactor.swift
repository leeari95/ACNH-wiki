//
//  TutorialReactor.swift
//  Animal-Crossing-Wiki
//
//  Created by Claude on 2026/01/01.
//

import Foundation
import ReactorKit
import RxSwift

final class TutorialReactor: Reactor {

    // MARK: - Properties

    let initialState: State

    private static let hasCompletedTutorialKey = "hasCompletedTutorial"
    private let totalPages: Int

    // MARK: - Action

    enum Action {
        case skip
        case complete
        case nextPage
        case setCurrentPage(Int)
    }

    // MARK: - Mutation

    enum Mutation {
        case setCompleted(Bool)
        case setCurrentPage(Int)
    }

    // MARK: - State

    struct State {
        var isCompleted: Bool = false
        var currentPage: Int = 0
        let totalPages: Int
    }

    // MARK: - Initialization

    init(totalPages: Int = 5) {
        self.totalPages = totalPages
        self.initialState = State(totalPages: totalPages)
    }

    // MARK: - Reactor

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .skip, .complete:
            return Observable.just(.setCompleted(true))
        case .nextPage:
            let nextPage = currentState.currentPage + 1
            if nextPage >= totalPages {
                return Observable.just(.setCompleted(true))
            } else {
                return Observable.just(.setCurrentPage(nextPage))
            }
        case .setCurrentPage(let page):
            return Observable.just(.setCurrentPage(page))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setCompleted(let isCompleted):
            newState.isCompleted = isCompleted
        case .setCurrentPage(let page):
            newState.currentPage = page
        }
        return newState
    }

    /// Side effect를 처리하기 위한 transform
    /// ReactorKit 패턴에서 side effect는 transform(mutation:)에서 처리하는 것이 적합
    func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
        return mutation.do(onNext: { mutation in
            switch mutation {
            case .setCompleted(let isCompleted):
                if isCompleted {
                    Self.setTutorialCompleted()
                }
            case .setCurrentPage:
                break
            }
        })
    }

    // MARK: - Static Methods

    static func shouldShowTutorial() -> Bool {
        return !UserDefaults.standard.bool(forKey: hasCompletedTutorialKey)
    }

    static func setTutorialCompleted() {
        UserDefaults.standard.set(true, forKey: hasCompletedTutorialKey)
    }

    static func resetTutorial() {
        UserDefaults.standard.set(false, forKey: hasCompletedTutorialKey)
    }
}

//
//  TutorialReactor.swift
//  Animal-Crossing-Wiki
//
//  Created by Claude on 2026/01/01.
//

import Foundation
import ReactorKit

final class TutorialReactor: Reactor {

    // MARK: - Properties

    let initialState: State

    private static let hasCompletedTutorialKey = "hasCompletedTutorial"

    // MARK: - Action

    enum Action {
        case skip
        case complete
    }

    // MARK: - Mutation

    enum Mutation {
        case setCompleted(Bool)
    }

    // MARK: - State

    struct State {
        var isCompleted: Bool = false
    }

    // MARK: - Initialization

    init() {
        self.initialState = State()
    }

    // MARK: - Reactor

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .skip, .complete:
            Self.setTutorialCompleted()
            return Observable.just(.setCompleted(true))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setCompleted(let isCompleted):
            newState.isCompleted = isCompleted
        }
        return newState
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

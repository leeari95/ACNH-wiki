//
//  AppSettingsViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/12.
//

import Foundation
import ReactorKit

final class AppSettingReactor: Reactor {
    
    enum Action {
        case toggleSwitch
    }
    
    enum Mutation {
        case setHapticState(_ isOn: Bool)
    }
    
    struct State {
        var currentHapticState: Bool = HapticManager.shared.mode == .on
    }
    
    let initialState: State
    
    init(state: State = State()) {
        self.initialState = state
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .toggleSwitch:
            HapticManager.shared.toggle()
            let isOn = HapticManager.shared.mode == .on
            return Observable.just(Mutation.setHapticState(isOn))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setHapticState(let isOn):
            newState.currentHapticState = isOn
        }
        return newState
    }
}

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
        case reset
        case restore
    }

    enum Mutation {
        case setHapticState(_ isOn: Bool)
        case reset(_ isReset: Bool)
        case restore(_ isRestore: Bool)
    }

    struct State {
        var currentHapticState: Bool = HapticManager.shared.mode == .on
    }

    let initialState: State
    private let storage: UserInfoStorage
    private let coordinator: DashboardCoordinator

    init(coordinator: DashboardCoordinator, state: State = State(), storage: UserInfoStorage = CoreDataUserInfoStorage()) {
        self.coordinator = coordinator
        self.initialState = state
        self.storage = storage
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .toggleSwitch:
            HapticManager.shared.toggle()
            let isOn = HapticManager.shared.mode == .on
            return Observable.just(Mutation.setHapticState(isOn))

        case .reset:
            return coordinator
                .showAlert(title: "Notice".localized, message: "Are you sure you want to reset it?".localized)
                .map { AppSettingReactor.Mutation.reset($0) }
                .observe(on: MainScheduler.asyncInstance)

        case .restore:
            return coordinator
                .showAlert(title: "Notice".localized, message: "Restore data from iCloud?".localized)
                .map { Mutation.restore($0) }
                .observe(on: MainScheduler.asyncInstance)
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setHapticState(let isOn):
            newState.currentHapticState = isOn

        case .reset(let isReset):
            if isReset {
                Items.shared.reset()
                storage.resetUserInfo()
                coordinator.transition(for: .dismiss)
            }

        case .restore(let isRestore):
            if isRestore {
                Items.shared.setUpUserCollection()
                coordinator.transition(for: .dismiss)
            }
        }
        return newState
    }
}

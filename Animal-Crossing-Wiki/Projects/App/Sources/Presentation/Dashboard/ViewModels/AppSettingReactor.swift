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
        case recoverFromCloud // TEMPORARY: Recovery
    }

    enum Mutation {
        case setHapticState(_ isOn: Bool)
        case reset(_ isReset: Bool)
        case setRecoveryInProgress(Bool) // TEMPORARY: Recovery
    }

    struct State {
        var currentHapticState: Bool = HapticManager.shared.mode == .on
        var isRecoveryInProgress: Bool = false // TEMPORARY: Recovery
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

        // TEMPORARY: Recovery
        case .recoverFromCloud:
            return coordinator
                .showAlert(
                    title: "iCloud Data Recovery".localized,
                    message: "This will reset local data and re-download from iCloud. Continue?".localized
                )
                .flatMap { confirmed -> Observable<Mutation> in
                    guard confirmed else { return .empty() }
                    return Observable.concat(
                        .just(.setRecoveryInProgress(true)),
                        self.performRecovery()
                    )
                }
                .observe(on: MainScheduler.asyncInstance)
        }
    }

    // TEMPORARY: Recovery
    private func performRecovery() -> Observable<Mutation> {
        return Observable.create { observer in
            CoreDataStorage.shared.performCloudKitRecovery { [weak self] result in
                switch result {
                case .success:
                    self?.coordinator.showRecoveryResultAlert(success: true, message: nil)
                case .failure(let error):
                    self?.coordinator.showRecoveryResultAlert(success: false, message: error.localizedDescription)
                }
                observer.onNext(.setRecoveryInProgress(false))
                observer.onCompleted()
            }
            return Disposables.create()
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

        // TEMPORARY: Recovery
        case .setRecoveryInProgress(let inProgress):
            newState.isRecoveryInProgress = inProgress
        }
        return newState
    }
}

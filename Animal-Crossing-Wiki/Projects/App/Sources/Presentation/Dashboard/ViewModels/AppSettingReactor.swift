//
//  AppSettingReactor.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/12.
//

import Foundation
import ReactorKit
import RxSwift

final class AppSettingReactor: Reactor {

    enum Action {
        case toggleHaptic
        case toggleNotification
        case reset
    }

    enum Mutation {
        case setHapticState(_ isOn: Bool)
        case setNotificationState(_ isOn: Bool)
        case reset(_ isReset: Bool)
    }

    struct State {
        var currentHapticState: Bool = HapticManager.shared.mode == .on
        var currentNotificationState: Bool = NotificationManager.shared.mode == .on
    }

    let initialState: State
    private let storage: UserInfoStorage
    private let coordinator: DashboardCoordinator
    private let disposeBag = DisposeBag()

    init(coordinator: DashboardCoordinator, state: State = State(), storage: UserInfoStorage = CoreDataUserInfoStorage()) {
        self.coordinator = coordinator
        self.initialState = state
        self.storage = storage
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .toggleHaptic:
            HapticManager.shared.toggle()
            let isOn = HapticManager.shared.mode == .on
            return Observable.just(Mutation.setHapticState(isOn))

        case .toggleNotification:
            return handleNotificationToggle()

        case .reset:
            return coordinator
                .showAlert(title: "Notice".localized, message: "Are you sure you want to reset it?".localized)
                .map { AppSettingReactor.Mutation.reset($0) }
                .observe(on: MainScheduler.asyncInstance)
        }
    }

    private func handleNotificationToggle() -> Observable<Mutation> {
        let notificationManager = NotificationManager.shared

        if notificationManager.mode == .on {
            notificationManager.toggle()
            return Observable.just(.setNotificationState(false))
        }

        return Observable.create { [weak self] observer in
            notificationManager.checkAuthorizationStatus { status in
                switch status {
                case .authorized:
                    notificationManager.toggle()
                    observer.onNext(.setNotificationState(true))
                    observer.onCompleted()

                case .notDetermined:
                    notificationManager.requestAuthorization { granted in
                        if granted {
                            notificationManager.setMode(.on)
                            observer.onNext(.setNotificationState(true))
                        } else {
                            observer.onNext(.setNotificationState(false))
                        }
                        observer.onCompleted()
                    }

                case .denied:
                    self?.showNotificationPermissionDeniedAlert()
                    observer.onNext(.setNotificationState(false))
                    observer.onCompleted()

                default:
                    observer.onNext(.setNotificationState(false))
                    observer.onCompleted()
                }
            }

            return Disposables.create()
        }
    }

    private func showNotificationPermissionDeniedAlert() {
        coordinator
            .showAlert(
                title: "Notification permission denied".localized,
                message: "Please enable notification permission in Settings.".localized
            )
            .take(1)
            .filter { $0 }
            .subscribe(onNext: { [weak self] _ in
                self?.coordinator.openAppSettings()
            })
            .disposed(by: disposeBag)
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setHapticState(let isOn):
            newState.currentHapticState = isOn

        case .setNotificationState(let isOn):
            newState.currentNotificationState = isOn

        case .reset(let isReset):
            if isReset {
                Items.shared.reset()
                storage.resetUserInfo()
                coordinator.transition(for: .dismiss)
            }
        }
        return newState
    }
}

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
        case recoverFromCloud
        case consolidateManually
        case restoreLocalBackup
        case loadSyncStatus
        case loadLocalBackupMetadata
    }

    enum Mutation {
        case setHapticState(_ isOn: Bool)
        case reset(_ isReset: Bool)
        case setRecoveryInProgress(Bool)
        case setConsolidationInProgress(Bool)
        case setLocalRestoreInProgress(Bool)
        case setSyncStatus(SyncStatusInfo)
        case setLocalBackupMetadata(SafetySnapshotService.Metadata?)
    }

    struct State {
        var currentHapticState: Bool = HapticManager.shared.mode == .on
        var isRecoveryInProgress: Bool = false
        var isConsolidationInProgress: Bool = false
        var isLocalRestoreInProgress: Bool = false
        var syncStatus: SyncStatusInfo?
        var localBackupMetadata: SafetySnapshotService.Metadata?
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

        case .loadSyncStatus:
            return Observable.create { observer in
                CoreDataStorage.shared.fetchSyncStatus { info in
                    observer.onNext(.setSyncStatus(info))
                    observer.onCompleted()
                }
                return Disposables.create()
            }

        case .recoverFromCloud:
            // 2단 확인: 복원은 로컬 데이터를 전부 지우므로 파괴적 동작
            return coordinator
                .showAlert(
                    title: "iCloud Data Recovery".localized,
                    message: "Recovery warning: local data will be erased".localized
                )
                .flatMap { [weak self] firstConfirmed -> Observable<Bool> in
                    guard let self, firstConfirmed else { return .just(false) }
                    return self.coordinator.showAlert(
                        title: "Are you absolutely sure?".localized,
                        message: "Recovery final confirm".localized
                    )
                }
                .flatMap { confirmed -> Observable<Mutation> in
                    guard confirmed else { return .empty() }
                    return Observable.concat(
                        .just(.setRecoveryInProgress(true)),
                        self.performRecovery()
                    )
                }
                .observe(on: MainScheduler.asyncInstance)

        case .consolidateManually:
            return coordinator
                .showAlert(
                    title: "Clean duplicate data".localized,
                    message: "Consolidate warning".localized
                )
                .flatMap { confirmed -> Observable<Mutation> in
                    guard confirmed else { return .empty() }
                    return Observable.concat(
                        .just(.setConsolidationInProgress(true)),
                        self.performConsolidation()
                    )
                }
                .observe(on: MainScheduler.asyncInstance)

        case .loadLocalBackupMetadata:
            let metadata = SafetySnapshotService.shared.readMetadata()
            return .just(.setLocalBackupMetadata(metadata))

        case .restoreLocalBackup:
            guard let metadata = SafetySnapshotService.shared.readMetadata() else {
                return .empty()
            }
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            let relative = formatter.localizedString(for: metadata.createdAt, relativeTo: Date())
            let message = String(
                format: "Restore local backup warning".localized,
                relative, metadata.totalChildCount
            )
            return coordinator
                .showAlert(title: "Restore from local backup".localized, message: message)
                .flatMap { confirmed -> Observable<Mutation> in
                    guard confirmed else { return .empty() }
                    return Observable.concat(
                        .just(.setLocalRestoreInProgress(true)),
                        self.performLocalRestore()
                    )
                }
                .observe(on: MainScheduler.asyncInstance)
        }
    }

    private func performLocalRestore() -> Observable<Mutation> {
        return Observable.create { [weak self] observer in
            SafetySnapshotService.shared.restore(
                to: CoreDataStorage.shared.persistentContainer
            ) { outcome in
                switch outcome {
                case .success(let count):
                    Items.shared.refreshUserCollection()
                    self?.coordinator.showLocalRestoreResult(success: true, message: String(format: "Restored %d items".localized, count))
                case .noSnapshot:
                    self?.coordinator.showLocalRestoreResult(success: false, message: "No local backup found".localized)
                case .failed(let error):
                    self?.coordinator.showLocalRestoreResult(success: false, message: error.localizedDescription)
                }
                observer.onNext(.setLocalRestoreInProgress(false))
                observer.onNext(.setLocalBackupMetadata(SafetySnapshotService.shared.readMetadata()))
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }

    private func performConsolidation() -> Observable<Mutation> {
        return Observable.create { observer in
            CoreDataStorage.shared.consolidateUserCollectionsManually {
                observer.onNext(.setConsolidationInProgress(false))
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }

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

        case .setRecoveryInProgress(let inProgress):
            newState.isRecoveryInProgress = inProgress

        case .setConsolidationInProgress(let inProgress):
            newState.isConsolidationInProgress = inProgress

        case .setLocalRestoreInProgress(let inProgress):
            newState.isLocalRestoreInProgress = inProgress

        case .setSyncStatus(let info):
            newState.syncStatus = info

        case .setLocalBackupMetadata(let metadata):
            newState.localBackupMetadata = metadata
        }
        return newState
    }
}

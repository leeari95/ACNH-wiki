//
//  SceneDelegate.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/05/04.
//

import UIKit
import CloudKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var appCoordinator: AppCoordinator?
    private var cloudImportToast: ToastView?
    private var importCount = 0
    private var toastTimeoutWork: DispatchWorkItem?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else {
            return
        }
        window = UIWindow(windowScene: windowScene)
        appCoordinator = AppCoordinator()
        appCoordinator?.start()
        window?.rootViewController = appCoordinator?.rootViewController
        window?.makeKeyAndVisible()
        observeCloudImport()
        observeCloudSyncErrors()
        observeAccountChanges()
        checkiCloudAccount()
        CoreDataStorage.shared.cleanupPersistentHistory()
    }

    // MARK: - iCloud Account Check

    private func checkiCloudAccount() {
        CoreDataStorage.shared.checkiCloudAccountStatus { [weak self] status in
            guard status != .available else { return }
            self?.showiCloudUnavailableAlert(status: status)
        }
    }

    private func observeAccountChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAccountChange(_:)),
            name: CoreDataStorage.iCloudAccountDidChange,
            object: nil
        )
    }

    @objc private func handleAccountChange(_ notification: Notification) {
        guard let rawValue = notification.userInfo?["status"] as? Int else { return }
        let status = CKAccountStatus(rawValue: rawValue) ?? .couldNotDetermine
        guard status != .available else { return }
        DispatchQueue.main.async { [weak self] in
            self?.showiCloudUnavailableAlert(status: status)
        }
    }

    private func showiCloudUnavailableAlert(status: CKAccountStatus) {
        let message: String
        switch status {
        case .noAccount:
            message = "iCloud is not signed in. Data will be saved locally only.".localized
        case .restricted:
            message = "iCloud access is restricted for this device.".localized
        case .temporarilyUnavailable:
            message = "iCloud is temporarily unavailable. Data will sync when available.".localized
        default:
            message = "iCloud status could not be determined. Data will be saved locally only.".localized
        }

        let alert = UIAlertController(title: "iCloud".localized, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK".localized, style: .default))
        window?.rootViewController?.present(alert, animated: true)
    }

    // MARK: - Cloud Import Toast

    private func observeCloudImport() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudImportStart),
            name: CoreDataStorage.didStartCloudImport,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudImportFinish),
            name: CoreDataStorage.didFinishCloudImport,
            object: nil
        )
    }

    @objc private func handleCloudImportStart() {
        DispatchQueue.main.async { [weak self] in
            guard let self, let window else { return }
            self.importCount += 1
            guard self.cloudImportToast == nil else { return }
            let toast = ToastView(message: "Fetching collection data from iCloud...".localized)
            self.cloudImportToast = toast
            toast.show(in: window)
            self.scheduleToastTimeout()
        }
    }

    @objc private func handleCloudImportFinish() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.importCount = max(self.importCount - 1, 0)
            guard self.importCount == 0 else { return }
            self.dismissImportToast()
        }
    }

    private func scheduleToastTimeout() {
        toastTimeoutWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.cloudImportToast != nil else { return }
            self.importCount = 0
            self.dismissImportToast()
        }
        toastTimeoutWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 60, execute: work)
    }

    private func dismissImportToast() {
        toastTimeoutWork?.cancel()
        toastTimeoutWork = nil
        cloudImportToast?.dismiss()
        cloudImportToast = nil
    }

    // MARK: - Cloud Sync Error

    private func observeCloudSyncErrors() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudSyncError(_:)),
            name: CoreDataStorage.cloudSyncDidFail,
            object: nil
        )
    }

    @objc private func handleCloudSyncError(_ notification: Notification) {
        guard let reason = notification.userInfo?["reason"] as? String else { return }
        DispatchQueue.main.async { [weak self] in
            let message: String
            switch reason {
            case "quota_exceeded":
                message = "iCloud storage is full. Please free up space to continue syncing.".localized
            case "not_authenticated":
                message = "iCloud is not signed in. Data will be saved locally only.".localized
            default:
                return
            }

            let alert = UIAlertController(title: "iCloud".localized, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK".localized, style: .default))
            self?.window?.rootViewController?.present(alert, animated: true)
        }
    }

    // MARK: - Scene Lifecycle

    func sceneDidDisconnect(_ scene: UIScene) {}

    func sceneDidBecomeActive(_ scene: UIScene) {
        Items.shared.refreshUserCollection()
    }

    func sceneWillResignActive(_ scene: UIScene) {}

    func sceneWillEnterForeground(_ scene: UIScene) {}

    func sceneDidEnterBackground(_ scene: UIScene) {
        var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
        backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
        }
    }

}

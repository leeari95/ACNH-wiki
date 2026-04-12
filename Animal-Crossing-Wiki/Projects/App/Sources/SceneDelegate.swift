//
//  SceneDelegate.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/05/04.
//

import UIKit
import CloudKit
import OSLog

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var appCoordinator: AppCoordinator?
    private var isAppSetup = false
    private var importObserver: NSObjectProtocol?
    private var pendingConnectionOptions: UIScene.ConnectionOptions?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else {
            return
        }
        window = UIWindow(windowScene: windowScene)
        pendingConnectionOptions = connectionOptions

        os_log(.info, log: .default, "🚀 App launch — checking fresh install")
        let isFresh = CoreDataStorage.shared.isFreshInstall()
        os_log(.info, log: .default, "🚀 isFreshInstall = %{public}@", isFresh ? "true" : "false")

        if isFresh {
            CoreDataStorage.shared.markWaitingForFirstImport()
            showSplashScreen()
            window?.makeKeyAndVisible()
            waitForCloudKitImport(timeout: 10) { [weak self] in
                self?.setupApp()
            }
        } else {
            setupApp()
        }
    }

    // MARK: - App Setup

    private func setupApp() {
        isAppSetup = true

        CoreDataStorage.shared.clearWaitingForFirstImport()
        CoreDataStorage.shared.logSyncDiagnostics(phase: "Pre-setup")
        CoreDataStorage.shared.consolidateUserCollections()

        appCoordinator = AppCoordinator()
        appCoordinator?.start()
        window?.rootViewController = appCoordinator?.rootViewController
        window?.makeKeyAndVisible()

        if let options = pendingConnectionOptions {
            restoreState(from: options)
            pendingConnectionOptions = nil
        }

        observeCloudImport()
        observeCloudSyncErrors()
        observeAccountChanges()
        checkiCloudAccount()
        CoreDataStorage.shared.cleanupPersistentHistory()
    }

    // MARK: - Fresh Install: Wait for CloudKit Import

    private func showSplashScreen() {
        window?.rootViewController = CloudSyncSplashViewController()
    }

    private func waitForCloudKitImport(timeout: TimeInterval, completion: @escaping () -> Void) {
        var hasCompleted = false

        // hasCompleted 접근을 main queue로 한정하여 race condition 방지
        let complete: (String) -> Void = { [weak self] reason in
            DispatchQueue.main.async {
                guard !hasCompleted else {
                    return
                }

                hasCompleted = true
                if let observer = self?.importObserver {
                    NotificationCenter.default.removeObserver(observer)
                    self?.importObserver = nil
                }
                os_log(.info, log: .default, "🚀 CloudKit wait finished (%{public}@) — launching app", reason)
                completion()
            }
        }

        // iCloud 계정 확인 — 미로그인이면 Import 대기 불필요
        CoreDataStorage.shared.checkiCloudAccountStatus { status in
            if status != .available {
                os_log(.info, log: .default, "🚀 iCloud not available (status=%d) — skipping wait", status.rawValue)
                complete("no-icloud")
            }
        }

        importObserver = NotificationCenter.default.addObserver(
            forName: CoreDataStorage.didFinishCloudImport,
            object: nil,
            queue: .main
        ) { _ in
            complete("import-arrived")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            complete("timeout")
        }
    }

    // MARK: - iCloud Account Check

    private func checkiCloudAccount() {
        CoreDataStorage.shared.checkiCloudAccountStatus { [weak self] status in
            guard status != .available else {
                return
            }
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
        guard let rawValue = notification.userInfo?["status"] as? Int else {
            return
        }
        let status = CKAccountStatus(rawValue: rawValue) ?? .couldNotDetermine
        guard status != .available else {
            return
        }
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
        presentAlert(alert)
    }

    private func presentAlert(_ alert: UIAlertController) {
        var presenter = window?.rootViewController
        while let presented = presenter?.presentedViewController {
            presenter = presented
        }
        presenter?.present(alert, animated: true)
    }

    // MARK: - Cloud Import Toast

    private func observeCloudImport() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudImportFinish(_:)),
            name: CoreDataStorage.didFinishCloudImport,
            object: nil
        )
    }

    @objc private func handleCloudImportFinish(_ notification: Notification) {
        // Persistent History 기반: 실제 CloudKit 데이터 변경이 있을 때만 토스트 표시
        let hasChanges = notification.userInfo?["hasChanges"] as? Bool ?? false
        guard hasChanges else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let owner = self, owner.isAppSetup else {
                return
            }

            ToastManager.shared.show(
                message: "Fetching collection data from iCloud...".localized,
                timeout: 3
            )
        }
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
        guard let reason = notification.userInfo?["reason"] as? String else {
            return
        }
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
            self?.presentAlert(alert)
        }
    }

    // MARK: - State Restoration

    private static let activityType = "leeari.NookPortalPlus.browsing"

    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        let activity = NSUserActivity(activityType: SceneDelegate.activityType)
        activity.userInfo = [
            "selectedTab": appCoordinator?.rootViewController.selectedIndex ?? 0
        ]
        return activity
    }

    private func restoreState(from connectionOptions: UIScene.ConnectionOptions) {
        let activity = connectionOptions.userActivities.first { $0.activityType == SceneDelegate.activityType }
        if let tabIndex = activity?.userInfo?["selectedTab"] as? Int {
            appCoordinator?.rootViewController.selectedIndex = tabIndex
        }
    }

    // MARK: - Scene Lifecycle

    func sceneDidDisconnect(_ scene: UIScene) {}

    func sceneDidBecomeActive(_ scene: UIScene) {
        // CloudKit 이벤트(didReceiveRemoteChanges/didFinishCloudImport)가
        // Items.swift의 debounced subscription(Path-B)을 통해 자동으로 데이터를 갱신하므로
        // 여기서 중복 호출하지 않음 (Path-A + Path-B 동시 실행 시 Synchronization anomaly 발생)
    }

    func sceneWillResignActive(_ scene: UIScene) {}

    func sceneWillEnterForeground(_ scene: UIScene) {}

    func sceneDidEnterBackground(_ scene: UIScene) {
        ToastManager.shared.dismiss()

        // Extend execution time for pending CloudKit sync operations (import/export)
        var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
        let endTask = {
            guard backgroundTaskID != .invalid else {
                return
            }
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(expirationHandler: endTask)

        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
            endTask()
        }
    }

}

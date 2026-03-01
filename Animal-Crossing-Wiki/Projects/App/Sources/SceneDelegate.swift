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
    private var cloudImportToast: ToastView?
    private var importCount = 0
    private var toastTimeoutWork: DispatchWorkItem?
    private var importObserver: NSObjectProtocol?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else {
            return
        }
        window = UIWindow(windowScene: windowScene)

        os_log(.info, log: .default, "🚀 App launch — checking fresh install")
        let isFresh = CoreDataStorage.shared.isFreshInstall()
        os_log(.info, log: .default, "🚀 isFreshInstall = %{public}@", isFresh ? "true" : "false")

        if isFresh {
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

        CoreDataStorage.shared.logSyncDiagnostics(phase: "Pre-setup")
        CoreDataStorage.shared.consolidateUserCollections()

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

    // MARK: - Fresh Install: Wait for CloudKit Import

    private func showSplashScreen() {
        window?.rootViewController = CloudSyncSplashViewController()
    }

    private func waitForCloudKitImport(timeout: TimeInterval, completion: @escaping () -> Void) {
        var hasCompleted = false

        let complete: (String) -> Void = { [weak self] reason in
            guard !hasCompleted else { return }
            hasCompleted = true
            if let observer = self?.importObserver {
                NotificationCenter.default.removeObserver(observer)
                self?.importObserver = nil
            }
            os_log(.info, log: .default, "🚀 CloudKit wait finished (%{public}@) — launching app", reason)
            DispatchQueue.main.async { completion() }
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
            guard let owner = self, owner.isAppSetup, let window = owner.window else {
                return
            }
            owner.importCount += 1
            guard owner.cloudImportToast == nil else {
                return
            }
            let toast = ToastView(message: "Fetching collection data from iCloud...".localized)
            owner.cloudImportToast = toast
            toast.show(in: window)
            owner.scheduleToastTimeout()
        }
    }

    @objc private func handleCloudImportFinish() {
        DispatchQueue.main.async { [weak self] in
            guard let owner = self, owner.isAppSetup else {
                return
            }
            owner.importCount = max(owner.importCount - 1, 0)
            guard owner.importCount == 0 else {
                return
            }
            owner.dismissImportToast()
            os_log(.info, log: .default, "🔄 [Path-C] handleCloudImportFinish — skip refresh (Items.swift handles it)")
            // Items.swift가 didFinishCloudImport을 직접 구독하므로 여기서 중복 호출하지 않음
        }
    }

    private func scheduleToastTimeout() {
        toastTimeoutWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let owner = self, owner.cloudImportToast != nil else {
                return
            }
            owner.importCount = 0
            owner.dismissImportToast()
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
            self?.window?.rootViewController?.present(alert, animated: true)
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
        dismissImportToast()
        importCount = 0

        var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
        backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
        }
    }

}

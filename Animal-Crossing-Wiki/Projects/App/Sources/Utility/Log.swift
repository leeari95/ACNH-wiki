//
//  Log.swift
//  ACNH-wiki
//
//  Created by Ari on 4/22/26.
//

import Foundation
import OSLog
import FirebaseCrashlytics
import FirebaseAnalytics

enum Log {

    // MARK: - Event Names (Analytics)

    enum Event: String {
        case recoveryTriggered = "sync_recovery_triggered"
        case orphanCleanup = "sync_orphan_cleanup"
        case ucConsolidated = "sync_uc_consolidated"
        case ucCreated = "sync_uc_created"
        case tokenExpired = "sync_token_expired"
        case ucMissing = "sync_user_collection_missing"
        case ucCreationSuppressed = "sync_uc_creation_suppressed"
        case cloudSyncFailed = "sync_cloud_failed"
    }

    /// Analytics event parameter keys. 동일 키가 여러 이벤트에서 재사용되므로 중앙화.
    enum Param {
        static let reason = "reason"
        static let path = "path"
        static let code = "code"
        static let entity = "entity"
        static let deleted = "deleted"
        static let total = "total"
        static let ucTotal = "uc_total"
        static let keptRelationships = "kept_relationships"
        static let message = "message"
        static let errorName = "name"

        // Sync flag keys (shared with Key below)
        static let waiting = "waiting"
        static let importing = "importing"
        static let reset = "reset"
        static let recoveryGrace = "recovery_grace"
    }

    // MARK: - Custom Key Names (Crashlytics)

    enum Key {
        static let ucCount = "sync_uc_count"
        static let itemCount = "sync_item_count"
        static let taskCount = "sync_task_count"
        static let villagerCount = "sync_villager_count"
        static let hasEverHadUC = "sync_has_ever_had_uc"
        static let isFreshInstall = "sync_is_fresh_install"
        static let isWaitingForFirstImport = "sync_waiting_first_import"
        static let isImportInProgress = "sync_import_in_progress"
        static let isSyncResetInProgress = "sync_reset_in_progress"
        static let isWithinRecoveryGracePeriod = "sync_within_recovery_grace"
        static let lastImportDate = "sync_last_import_at"
        static let lastExportDate = "sync_last_export_at"
        static let appVersion = "sync_app_version"
    }

    // MARK: - Internal

    private static let crashlytics = Crashlytics.crashlytics()
    private static let analyticsStringLimit = 100

    private static func truncate(_ message: String) -> String {
        guard message.count > analyticsStringLimit else {
            return message
        }
        return String(message.prefix(analyticsStringLimit))
    }

    // MARK: - Level-based Logging
    //
    // 모든 레벨은 세 갈래로 전송된다:
    //   1) os_log            — Console.app / Xcode에서 로컬 확인
    //   2) Crashlytics.log   — 세션 breadcrumb (크래시/비치명 에러 발생 시 함께 업로드)
    //   3) Analytics.logEvent — Firebase Analytics 콘솔에 집계 (에러 없이도 가시성 확보)
    //
    // Analytics 파라미터 값은 100자로 자동 truncate된다.
    // verbose/debug는 Analytics 쿼터 보호를 위해 DEBUG 빌드에서만 Analytics로 전송된다.

    private static func emit(level: String, symbol: String, osLogType: OSLogType, message: String, sendToAnalytics: Bool) {
        crashlytics.log("[\(level.uppercased())] \(message)")
        os_log(osLogType, log: .default, "%{public}@ %{public}@", symbol, message)
        guard sendToAnalytics else {
            return
        }
        Analytics.logEvent("log_\(level)", parameters: [Param.message: truncate(message)])
    }

    static func verbose(_ message: String) {
        #if DEBUG
        emit(level: "verbose", symbol: "🔍", osLogType: .debug, message: message, sendToAnalytics: true)
        #else
        emit(level: "verbose", symbol: "🔍", osLogType: .debug, message: message, sendToAnalytics: false)
        #endif
    }

    static func debug(_ message: String) {
        #if DEBUG
        emit(level: "debug", symbol: "🐛", osLogType: .debug, message: message, sendToAnalytics: true)
        #else
        emit(level: "debug", symbol: "🐛", osLogType: .debug, message: message, sendToAnalytics: false)
        #endif
    }

    static func info(_ message: String) {
        emit(level: "info", symbol: "ℹ️", osLogType: .info, message: message, sendToAnalytics: true)
    }

    static func warning(_ message: String) {
        emit(level: "warning", symbol: "⚠️", osLogType: .error, message: message, sendToAnalytics: true)
    }

    // MARK: - Non-fatal Error

    /// Crashlytics 비치명 에러 업로드. 세션의 breadcrumb + custom keys가 함께 전송된다.
    /// 사용자 클레임 추적의 핵심 진입점.
    static func error(
        name: String,
        reason: String,
        userInfo: [String: Any] = [:]
    ) {
        var info = userInfo
        info[NSLocalizedDescriptionKey] = reason
        let nsError = NSError(domain: "Log.\(name)", code: 0, userInfo: info)
        crashlytics.record(error: nsError)
        os_log(.error, log: .default, "❗️ non-fatal: %{public}@ — %{public}@", name, reason)
        Analytics.logEvent("log_error", parameters: [
            Param.errorName: truncate(name),
            Param.reason: truncate(reason)
        ])
    }

    // MARK: - Analytics

    static func event(_ event: Event, parameters: [String: Any] = [:]) {
        Analytics.logEvent(event.rawValue, parameters: parameters)
        crashlytics.log("[EVENT] \(event.rawValue) \(parameters)")
        os_log(.info, log: .default, "📈 %{public}@", event.rawValue)
    }

    /// 사용자 탭/클릭 추적. Firebase Analytics의 `select_content` 스키마로 기록.
    static func click(_ name: String, parameters: [String: Any] = [:]) {
        var params = parameters
        params[AnalyticsParameterItemID] = name
        params[AnalyticsParameterContentType] = "click"
        Analytics.logEvent(AnalyticsEventSelectContent, parameters: params)
        os_log(.info, log: .default, "👆 click=%{public}@", name)
    }

    // MARK: - Context (Crashlytics custom keys)

    static func setContext(_ key: String, _ value: Any?) {
        guard let value else {
            crashlytics.setCustomValue("", forKey: key)
            return
        }
        crashlytics.setCustomValue(value, forKey: key)
    }

    /// 엔티티 카운트와 sync 플래그를 한 번에 custom keys로 전송.
    struct Snapshot {
        var ucCount: Int
        var itemCount: Int
        var taskCount: Int
        var villagerCount: Int
        var hasEverHadUC: Bool
        var isFreshInstall: Bool?
        var isWaitingForFirstImport: Bool
        var isImportInProgress: Bool
        var isSyncResetInProgress: Bool
        var isWithinRecoveryGracePeriod: Bool
        var lastImportDate: Date?
        var lastExportDate: Date?
    }

    static func snapshot(_ snapshot: Snapshot) {
        setContext(Key.ucCount, snapshot.ucCount)
        setContext(Key.itemCount, snapshot.itemCount)
        setContext(Key.taskCount, snapshot.taskCount)
        setContext(Key.villagerCount, snapshot.villagerCount)
        setContext(Key.hasEverHadUC, snapshot.hasEverHadUC)
        if let isFreshInstall = snapshot.isFreshInstall {
            setContext(Key.isFreshInstall, isFreshInstall)
        }
        setContext(Key.isWaitingForFirstImport, snapshot.isWaitingForFirstImport)
        setContext(Key.isImportInProgress, snapshot.isImportInProgress)
        setContext(Key.isSyncResetInProgress, snapshot.isSyncResetInProgress)
        setContext(Key.isWithinRecoveryGracePeriod, snapshot.isWithinRecoveryGracePeriod)
        setContext(Key.lastImportDate, snapshot.lastImportDate?.timeIntervalSince1970 ?? 0)
        setContext(Key.lastExportDate, snapshot.lastExportDate?.timeIntervalSince1970 ?? 0)

        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            setContext(Key.appVersion, version)
        }
    }
}

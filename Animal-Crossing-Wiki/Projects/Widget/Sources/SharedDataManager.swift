//
//  SharedDataManager.swift
//  ACNHWidget
//
//  Created by Claude on 2025/01/01.
//

import Foundation
import WidgetKit
import os.log

/// App Group을 통해 메인 앱과 위젯 간 데이터를 공유하는 매니저
/// 메인 앱에서 데이터 변경 시 이 매니저를 통해 UserDefaults에 저장하고,
/// 위젯에서는 이 데이터를 읽어와 표시합니다.
///
/// # 사용법
/// 메인 앱에서 데이터 변경 시:
/// ```swift
/// SharedDataManager.shared.saveDailyTasks(tasks)
/// // 위젯이 자동으로 갱신됩니다.
/// ```
final class SharedDataManager {

    // MARK: - Constants

    /// App Group Identifier
    /// 실제 사용 시 Apple Developer Portal에서 생성한 App Group ID로 변경 필요
    static let appGroupIdentifier = "group.leeari.NookPortalPlus"

    /// Widget Kind 상수
    enum WidgetKind {
        static let dailyTask = "DailyTaskWidget"
        static let collectionProgress = "CollectionProgressWidget"
    }

    /// 위젯 딥링크 URL
    /// 메인 앱에서 이 URL 스킴을 처리하여 해당 화면으로 이동해야 합니다.
    enum DeepLink {
        static let dailyTasks = URL(string: "acnh://dailytasks")!
        static let collection = URL(string: "acnh://collection")!
    }

    /// UserDefaults Keys
    private enum Keys {
        static let dailyTasks = "widget.dailyTasks"
        static let collectionProgress = "widget.collectionProgress"
        static let lastUpdated = "widget.lastUpdated"
        static let userName = "widget.userName"
        static let islandName = "widget.islandName"
    }

    // MARK: - Shared Instance

    static let shared = SharedDataManager()

    // MARK: - Properties

    private let userDefaults: UserDefaults?
    private let logger = Logger(subsystem: "leeari.NookPortalPlus.Widget", category: "SharedDataManager")

    // MARK: - Initialization

    private init() {
        userDefaults = UserDefaults(suiteName: SharedDataManager.appGroupIdentifier)
        #if DEBUG
        if userDefaults == nil {
            assertionFailure("SharedDataManager: App Group UserDefaults 초기화 실패. App Group ID를 확인하세요: \(SharedDataManager.appGroupIdentifier)")
        }
        #endif
    }

    // MARK: - Daily Tasks

    /// 위젯용 일일 할일 데이터 모델
    struct WidgetDailyTask: Codable, Identifiable {
        let id: UUID
        let name: String
        let icon: String
        let completedCount: Int
        let totalCount: Int

        var isCompleted: Bool {
            completedCount >= totalCount
        }

        var progressText: String {
            "\(completedCount)/\(totalCount)"
        }
    }

    /// 일일 할일 목록 저장
    /// - Parameter tasks: 저장할 일일 할일 목록
    /// - Note: 저장 후 DailyTaskWidget 타임라인이 자동으로 갱신됩니다.
    func saveDailyTasks(_ tasks: [WidgetDailyTask]) {
        guard let userDefaults = userDefaults else { return }

        do {
            let data = try JSONEncoder().encode(tasks)
            userDefaults.set(data, forKey: Keys.dailyTasks)
            userDefaults.set(Date(), forKey: Keys.lastUpdated)
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.dailyTask)
        } catch {
            logger.error("Failed to encode daily tasks: \(error.localizedDescription)")
        }
    }

    /// 일일 할일 목록 불러오기
    func loadDailyTasks() -> [WidgetDailyTask] {
        guard let userDefaults = userDefaults,
              let data = userDefaults.data(forKey: Keys.dailyTasks) else {
            return Self.sampleDailyTasks
        }

        do {
            return try JSONDecoder().decode([WidgetDailyTask].self, from: data)
        } catch {
            logger.error("Failed to decode daily tasks: \(error.localizedDescription)")
            return Self.sampleDailyTasks
        }
    }

    // MARK: - Collection Progress

    /// 위젯용 수집 진행률 데이터 모델
    struct WidgetCollectionProgress: Codable, Identifiable {
        let id: String
        let categoryName: String
        let iconName: String
        let collectedCount: Int
        let totalCount: Int

        var progress: Double {
            guard totalCount > 0 else { return 0 }
            return Double(collectedCount) / Double(totalCount)
        }

        var progressText: String {
            "\(collectedCount)/\(totalCount)"
        }

        var percentageText: String {
            let percentage = Int(progress * 100)
            return "\(percentage)%"
        }
    }

    /// 수집 진행률 저장
    /// - Parameter progress: 저장할 수집 진행률 목록
    /// - Note: 저장 후 CollectionProgressWidget 타임라인이 자동으로 갱신됩니다.
    func saveCollectionProgress(_ progress: [WidgetCollectionProgress]) {
        guard let userDefaults = userDefaults else { return }

        do {
            let data = try JSONEncoder().encode(progress)
            userDefaults.set(data, forKey: Keys.collectionProgress)
            userDefaults.set(Date(), forKey: Keys.lastUpdated)
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.collectionProgress)
        } catch {
            logger.error("Failed to encode collection progress: \(error.localizedDescription)")
        }
    }

    /// 수집 진행률 불러오기
    func loadCollectionProgress() -> [WidgetCollectionProgress] {
        guard let userDefaults = userDefaults,
              let data = userDefaults.data(forKey: Keys.collectionProgress) else {
            return Self.sampleCollectionProgress
        }

        do {
            return try JSONDecoder().decode([WidgetCollectionProgress].self, from: data)
        } catch {
            logger.error("Failed to decode collection progress: \(error.localizedDescription)")
            return Self.sampleCollectionProgress
        }
    }

    // MARK: - User Info

    /// 사용자 이름 저장
    func saveUserName(_ name: String) {
        userDefaults?.set(name, forKey: Keys.userName)
    }

    /// 사용자 이름 불러오기
    func loadUserName() -> String {
        userDefaults?.string(forKey: Keys.userName) ?? "Player"
    }

    /// 섬 이름 저장
    func saveIslandName(_ name: String) {
        userDefaults?.set(name, forKey: Keys.islandName)
    }

    /// 섬 이름 불러오기
    func loadIslandName() -> String {
        userDefaults?.string(forKey: Keys.islandName) ?? "Island"
    }

    /// 마지막 업데이트 시간 불러오기
    func loadLastUpdated() -> Date? {
        userDefaults?.object(forKey: Keys.lastUpdated) as? Date
    }

    // MARK: - Sample Data (Preview & Placeholder용)

    static let sampleDailyTasks: [WidgetDailyTask] = [
        WidgetDailyTask(id: UUID(), name: "Hit rocks", icon: "Inv167", completedCount: 4, totalCount: 6),
        WidgetDailyTask(id: UUID(), name: "Find fossils", icon: "Inv60", completedCount: 4, totalCount: 4),
        WidgetDailyTask(id: UUID(), name: "Find furniture", icon: "Inv63", completedCount: 1, totalCount: 2),
        WidgetDailyTask(id: UUID(), name: "Obtain DIY", icon: "Inv48", completedCount: 0, totalCount: 1),
        WidgetDailyTask(id: UUID(), name: "Bottle message", icon: "Inv105", completedCount: 1, totalCount: 1),
        WidgetDailyTask(id: UUID(), name: "Buried bell", icon: "Inv107", completedCount: 0, totalCount: 1)
    ]

    static let sampleCollectionProgress: [WidgetCollectionProgress] = [
        WidgetCollectionProgress(id: "fishes", categoryName: "Fishes", iconName: "Fish6", collectedCount: 65, totalCount: 80),
        WidgetCollectionProgress(id: "bugs", categoryName: "Bugs", iconName: "Ins13", collectedCount: 72, totalCount: 80),
        WidgetCollectionProgress(id: "seaCreatures", categoryName: "Sea Creatures", iconName: "div25", collectedCount: 35, totalCount: 40),
        WidgetCollectionProgress(id: "fossils", categoryName: "Fossils", iconName: "icon-fossil", collectedCount: 70, totalCount: 73),
        WidgetCollectionProgress(id: "art", categoryName: "Art", iconName: "icon-board", collectedCount: 38, totalCount: 43)
    ]
}

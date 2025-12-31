//
//  CoreDataStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/09.
//

import Foundation
import CoreData
import os.log

// MARK: - Error Types

enum CoreDataStorageError: LocalizedError {
    case readError(Error)
    case notFound
    case categoryNotFound
    case initializationFailed(Error)
    case persistentStoreDescriptionNotFound
    case storeNotReady

    var errorDescription: String? {
        switch self {
        case .readError(let error):
            return "데이터 불러오기 실패\n에러내용: \(error.localizedDescription)"
        case .notFound:
            return "데이터를 찾지 못했습니다."
        case .categoryNotFound:
            return "카테고리가 존재하지 않는 아이템입니다."
        case .initializationFailed(let error):
            return "Core Data 초기화 실패: \(error.localizedDescription)"
        case .persistentStoreDescriptionNotFound:
            return "Persistent Store Description을 찾을 수 없습니다."
        case .storeNotReady:
            return "저장소가 아직 준비되지 않았습니다."
        }
    }
}

// MARK: - Configuration

enum CloudKitConfiguration {
    static var containerIdentifier: String {
        #if DEBUG
        return "iCloud.com.leeari95.ACNHWiki.dev"
        #else
        return "iCloud.com.leeari95.ACNHWiki"
        #endif
    }

    static var isCloudKitEnabled: Bool {
        return FileManager.default.ubiquityIdentityToken != nil
    }
}

// MARK: - Logger

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ACNHWiki", category: "CoreDataStorage")

// MARK: - CoreDataStorage

final class CoreDataStorage {

    static let shared = CoreDataStorage()

    // MARK: - Thread Safety

    /// 상태 접근을 동기화하기 위한 serial queue
    private let stateQueue = DispatchQueue(label: "com.leeari95.ACNHWiki.CoreDataStorage.stateQueue")

    /// 히스토리 처리를 직렬화하기 위한 serial queue
    private let historyProcessingQueue = DispatchQueue(label: "com.leeari95.ACNHWiki.CoreDataStorage.historyProcessing")

    private var _historyToken: NSPersistentHistoryToken?
    private var historyToken: NSPersistentHistoryToken? {
        get { stateQueue.sync { _historyToken } }
        set { stateQueue.sync { _historyToken = newValue } }
    }

    private var _isStoreLoaded = false
    /// 스토어 로드 완료 여부 (Thread-safe)
    var isStoreLoaded: Bool {
        get { stateQueue.sync { _isStoreLoaded } }
    }
    private func setStoreLoaded(_ value: Bool) {
        stateQueue.sync { _isStoreLoaded = value }
    }

    private var _lastPurgeDate: Date?
    private var lastPurgeDate: Date? {
        get { stateQueue.sync { _lastPurgeDate } }
        set { stateQueue.sync { _lastPurgeDate = newValue } }
    }

    private let tokenKey = "CoreDataStorage.lastHistoryToken"
    private let purgeInterval: TimeInterval = 86400 // 24시간

    /// 스토어 로드 완료를 알리는 semaphore
    private let storeLoadedSemaphore = DispatchSemaphore(value: 0)

    // 싱글톤이므로 앱 생명주기 동안 해제되지 않음 - NotificationCenter observer 해제 불필요
    private init() {
        loadHistoryToken()
    }

    // MARK: - Persistent Container

    private(set) lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "CoreDataStorage")

        guard let description = container.persistentStoreDescriptions.first else {
            // description이 없는 경우는 심각한 설정 오류이므로 로그 후 빈 컨테이너 반환
            // 이후 isStoreLoaded가 false로 유지되어 안전하게 처리됨
            logger.critical("Failed to retrieve a persistent store description. Core Data operations will fail.")
            return container
        }

        // iCloud 동기화가 가능한 경우에만 CloudKit 옵션 설정
        if CloudKitConfiguration.isCloudKitEnabled {
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: CloudKitConfiguration.containerIdentifier
            )
        } else {
            // iCloud가 비활성화된 경우 로컬 전용 모드
            description.cloudKitContainerOptions = nil
            logger.info("iCloud is not available. Using local-only storage.")
        }

        // 원격 변경사항 알림 활성화
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // 히스토리 추적 활성화 (동기화에 필요)
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

        // 스토어 로드 (콜백 내에서 완료 상태 설정)
        container.loadPersistentStores { [weak self] (storeDescription, error) in
            guard let self = self else { return }

            if let error = error as NSError? {
                logger.error("Failed to load persistent stores: \(error.localizedDescription), \(error.userInfo)")
                // CloudKit 에러 발생 시 로컬 전용 모드로 폴백
                if CloudKitConfiguration.isCloudKitEnabled {
                    self.retryLoadWithLocalOnlyMode(container: container, description: description)
                } else {
                    // 로컬 모드에서도 실패하면 앱이 계속 실행되지만 isStoreLoaded가 false로 유지됨
                    self.storeLoadedSemaphore.signal()
                }
            } else {
                logger.info("Persistent store loaded successfully: \(storeDescription.url?.absoluteString ?? "unknown")")
                self.setStoreLoaded(true)
                self.storeLoadedSemaphore.signal()
            }
        }

        // 자동 병합 정책 설정
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.name = "ViewContext"

        // Notification 설정
        setupRemoteChangeNotification(for: container)

        return container
    }()

    // MARK: - Store Load Waiting

    /// 스토어 로드가 완료될 때까지 대기합니다.
    /// - Parameter timeout: 최대 대기 시간 (초)
    /// - Returns: 타임아웃 발생 시 false
    @discardableResult
    func waitForStoreLoad(timeout: TimeInterval = 10.0) -> Bool {
        // 이미 로드되었으면 즉시 반환
        if isStoreLoaded { return true }

        // persistentContainer에 접근하여 lazy 초기화 트리거
        _ = persistentContainer

        // 로드 완료 대기
        let result = storeLoadedSemaphore.wait(timeout: .now() + timeout)
        if result == .timedOut {
            logger.error("Timed out waiting for store to load.")
            return false
        }
        // 다음 대기자를 위해 다시 signal (semaphore를 바이너리 세마포어처럼 사용)
        storeLoadedSemaphore.signal()
        return isStoreLoaded
    }

    // MARK: - Error Handling

    /// CloudKit 오류 시 로컬 전용 모드로 재시도합니다.
    /// 이 메서드는 첫 번째 loadPersistentStores 콜백 내에서만 호출되어야 합니다.
    private func retryLoadWithLocalOnlyMode(
        container: NSPersistentCloudKitContainer,
        description: NSPersistentStoreDescription
    ) {
        // 기존에 부분적으로 로드된 스토어가 있다면 제거
        for store in container.persistentStoreCoordinator.persistentStores {
            do {
                try container.persistentStoreCoordinator.remove(store)
                logger.info("Removed existing persistent store for retry.")
            } catch {
                logger.warning("Failed to remove existing store: \(error.localizedDescription)")
            }
        }

        // 스토어 파일 삭제 시도
        if let storeURL = description.url {
            do {
                try container.persistentStoreCoordinator.destroyPersistentStore(
                    at: storeURL,
                    ofType: NSSQLiteStoreType,
                    options: nil
                )
                logger.info("Destroyed existing persistent store for retry.")
            } catch {
                logger.warning("Failed to destroy existing store: \(error.localizedDescription)")
            }
        }

        // CloudKit 옵션 제거 후 재시도 (이 설정은 앱 재시작 시까지 유지됨)
        description.cloudKitContainerOptions = nil
        logger.warning("Retrying with local-only storage due to CloudKit error. iCloud sync disabled until app restart.")

        container.loadPersistentStores { [weak self] (_, retryError) in
            guard let self = self else { return }

            if let retryError = retryError {
                logger.critical("Failed to load persistent stores even in local-only mode: \(retryError.localizedDescription)")
            } else {
                self.setStoreLoaded(true)
                logger.info("Successfully loaded persistent store in local-only mode.")
            }
            self.storeLoadedSemaphore.signal()
        }
    }

    // MARK: - Remote Change Notification

    private func setupRemoteChangeNotification(for container: NSPersistentCloudKitContainer) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRemoteChange(_:)),
            name: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator
        )
    }

    @objc private func handleRemoteChange(_ notification: Notification) {
        // 히스토리 처리를 직렬화하여 race condition 방지
        historyProcessingQueue.async { [weak self] in
            guard let self = self, self.isStoreLoaded else { return }

            self.persistentContainer.performBackgroundTask { context in
                context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                context.transactionAuthor = "CloudKitSync"
                self.processRemoteChanges(in: context)
            }
        }
    }

    // MARK: - Persistent History Processing

    /// 원격 변경사항을 처리합니다.
    /// - Note: 이 메서드는 historyProcessingQueue에서 직렬화되어 호출되므로 thread-safe합니다.
    private func processRemoteChanges(in context: NSManagedObjectContext) {
        context.name = "RemoteChangesContext"

        // 토큰 읽기와 쓰기를 atomic하게 처리
        let currentToken = historyToken

        // 마지막 토큰 이후의 히스토리 가져오기
        let request = NSPersistentHistoryChangeRequest.fetchHistory(after: currentToken)

        if let storeCoordinator = context.persistentStoreCoordinator,
           let store = storeCoordinator.persistentStores.first {
            request.affectedStores = [store]
        }

        do {
            guard let result = try context.execute(request) as? NSPersistentHistoryResult,
                  let transactions = result.result as? [NSPersistentHistoryTransaction],
                  !transactions.isEmpty else {
                return
            }

            // 새로운 토큰 저장
            if let lastToken = transactions.last?.token {
                historyToken = lastToken
                saveHistoryToken()
            }

            // 변경된 엔티티 식별
            let changedEntityNames = Set(transactions.flatMap { transaction in
                transaction.changes?.compactMap { $0.changedObjectID.entity.name } ?? []
            })

            logger.debug("Remote changes detected for entities: \(changedEntityNames)")

            // UI 갱신을 위한 알림 전송
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .didReceiveRemoteChanges,
                    object: nil,
                    userInfo: ["changedEntities": changedEntityNames]
                )
            }

            // 오래된 히스토리 정리 (일정 간격으로만)
            purgeOldHistoryIfNeeded(in: context)

        } catch {
            logger.error("Failed to process persistent history: \(error.localizedDescription)")
        }
    }

    private func purgeOldHistoryIfNeeded(in context: NSManagedObjectContext) {
        // 마지막 정리 후 24시간이 지났는지 확인
        if let lastPurge = lastPurgeDate,
           Date().timeIntervalSince(lastPurge) < purgeInterval {
            return
        }

        // 7일 이상 된 히스토리 삭제
        let calendar = Calendar.current
        guard let purgeDate = calendar.date(byAdding: .day, value: -7, to: Date()) else { return }

        let purgeRequest = NSPersistentHistoryChangeRequest.deleteHistory(before: purgeDate)

        do {
            try context.execute(purgeRequest)
            lastPurgeDate = Date()
            logger.debug("Purged persistent history older than 7 days.")
        } catch {
            logger.warning("Failed to purge old history: \(error.localizedDescription)")
        }
    }

    // MARK: - History Token Persistence

    private func loadHistoryToken() {
        guard let tokenData = UserDefaults.standard.data(forKey: tokenKey) else { return }

        do {
            _historyToken = try NSKeyedUnarchiver.unarchivedObject(
                ofClass: NSPersistentHistoryToken.self,
                from: tokenData
            )
        } catch {
            logger.warning("Failed to load history token: \(error.localizedDescription)")
        }
    }

    private func saveHistoryToken() {
        guard let token = historyToken else { return }

        do {
            let tokenData = try NSKeyedArchiver.archivedData(
                withRootObject: token,
                requiringSecureCoding: true
            )
            UserDefaults.standard.set(tokenData, forKey: tokenKey)
        } catch {
            logger.warning("Failed to save history token: \(error.localizedDescription)")
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// iCloud에서 원격 변경사항이 수신되었을 때 발송됩니다.
    /// userInfo에 "changedEntities" 키로 변경된 엔티티 이름들이 Set<String>으로 포함됩니다.
    static let didReceiveRemoteChanges = Notification.Name("CoreDataStorage.didReceiveRemoteChanges")
}

// MARK: - Background Task & User Collection

extension CoreDataStorage {

    /// Background task를 실행하며, context에 적절한 mergePolicy를 설정합니다.
    /// - Parameter block: 실행할 블록
    /// - Throws: CoreDataStorageError.storeNotReady - 스토어가 아직 로드되지 않은 경우
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        guard isStoreLoaded else {
            logger.warning("performBackgroundTask called before store is loaded. Waiting...")
            // 스토어 로드를 기다림 (최대 5초)
            guard waitForStoreLoad(timeout: 5.0) else {
                logger.error("Store still not loaded after waiting. Skipping background task.")
                return
            }
        }

        persistentContainer.performBackgroundTask { context in
            // Background context에도 동일한 merge policy 적용
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            context.transactionAuthor = Bundle.main.bundleIdentifier ?? "ACNHWiki"
            block(context)
        }
    }

    /// 사용자 컬렉션을 가져옵니다. 존재하지 않으면 새로 생성합니다.
    /// - Note: 새 엔티티 생성 시 호출자가 saveContext()를 호출해야 합니다.
    /// - Note: iCloud 환경에서는 중복 엔티티가 생성될 수 있으므로,
    ///         앱 레벨에서 mergeUserCollectionsIfNeeded를 호출하여 중복을 처리하세요.
    /// - Parameter context: 사용할 Managed Object Context
    /// - Returns: UserCollectionEntity 또는 새로 생성된 엔티티
    /// - Throws: CoreDataStorageError.storeNotReady 또는 Core Data fetch 관련 에러
    func getUserCollection(_ context: NSManagedObjectContext) throws -> UserCollectionEntity {
        guard isStoreLoaded else {
            throw CoreDataStorageError.storeNotReady
        }

        let request = UserCollectionEntity.fetchRequest()
        request.fetchLimit = 1

        let results = try context.fetch(request)

        if let existingCollection = results.first {
            return existingCollection
        }

        // 새 엔티티 생성
        logger.info("Creating new UserCollectionEntity")
        return UserCollectionEntity(UserInfo(), context: context)
    }

    /// 사용자 컬렉션이 존재하는지만 확인합니다 (생성하지 않음).
    /// - Parameter context: 사용할 Managed Object Context
    /// - Returns: UserCollectionEntity가 존재하면 반환, 없으면 nil
    /// - Throws: CoreDataStorageError.storeNotReady 또는 Core Data fetch 관련 에러
    func fetchExistingUserCollection(_ context: NSManagedObjectContext) throws -> UserCollectionEntity? {
        guard isStoreLoaded else {
            throw CoreDataStorageError.storeNotReady
        }

        let request = UserCollectionEntity.fetchRequest()
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    /// 중복된 UserCollectionEntity를 병합합니다.
    /// iCloud 동기화로 인해 중복이 발생했을 경우 호출합니다.
    /// - Note: 가장 많은 관계 데이터를 가진 컬렉션을 메인으로 선택합니다.
    /// - Parameter context: 사용할 Managed Object Context
    /// - Returns: 병합 후 남은 단일 UserCollectionEntity
    /// - Throws: CoreDataStorageError.storeNotReady 또는 Core Data fetch 관련 에러
    func mergeUserCollectionsIfNeeded(_ context: NSManagedObjectContext) throws -> UserCollectionEntity? {
        guard isStoreLoaded else {
            throw CoreDataStorageError.storeNotReady
        }

        let request = UserCollectionEntity.fetchRequest()
        let collections = try context.fetch(request)

        guard collections.count > 1 else {
            return collections.first
        }

        logger.warning("Found \(collections.count) duplicate UserCollectionEntity. Merging...")

        // 가장 많은 관계 데이터를 가진 컬렉션을 메인으로 선택
        let mainCollection = collections.max { lhs, rhs in
            let lhsCount = countRelationships(for: lhs)
            let rhsCount = countRelationships(for: rhs)
            return lhsCount < rhsCount
        } ?? collections[0]

        // 중복된 컬렉션의 관계 데이터를 메인으로 이전
        for duplicateCollection in collections where duplicateCollection !== mainCollection {
            mergeRelationships(from: duplicateCollection, to: mainCollection)

            // 사용자 정보 병합 (비어있지 않은 값 우선)
            if mainCollection.islandName == nil || mainCollection.islandName?.isEmpty == true {
                mainCollection.islandName = duplicateCollection.islandName
            }
            if mainCollection.name == nil || mainCollection.name?.isEmpty == true {
                mainCollection.name = duplicateCollection.name
            }
            if mainCollection.hemisphere == nil || mainCollection.hemisphere?.isEmpty == true {
                mainCollection.hemisphere = duplicateCollection.hemisphere
            }
            if mainCollection.islandFruit == nil || mainCollection.islandFruit?.isEmpty == true {
                mainCollection.islandFruit = duplicateCollection.islandFruit
            }
            if mainCollection.islandReputation == 0 {
                mainCollection.islandReputation = duplicateCollection.islandReputation
            }

            // 중복 엔티티 삭제
            context.delete(duplicateCollection)
        }

        logger.info("Merged duplicate UserCollectionEntity. Remaining: 1")
        return mainCollection
    }

    /// 컬렉션의 관계 데이터 개수를 계산합니다.
    private func countRelationships(for collection: UserCollectionEntity) -> Int {
        var count = 0
        count += (collection.critters as? Set<ItemEntity>)?.count ?? 0
        count += (collection.dailyTasks as? Set<DailyTaskEntity>)?.count ?? 0
        count += (collection.npcLike as? Set<NPCLikeEntity>)?.count ?? 0
        count += (collection.villagersHouse as? Set<VillagersHouseEntity>)?.count ?? 0
        count += (collection.villagersLike as? Set<VillagersLikeEntity>)?.count ?? 0
        return count
    }

    /// 중복 컬렉션의 관계 데이터를 메인 컬렉션으로 이전합니다.
    /// 이미 메인 컬렉션에 존재하는 항목은 스킵합니다.
    private func mergeRelationships(from source: UserCollectionEntity, to destination: UserCollectionEntity) {
        // 기존 항목들의 식별자를 수집하여 중복 체크에 사용
        let existingCritterNames = Set((destination.critters as? Set<ItemEntity>)?.compactMap { $0.name } ?? [])
        let existingDailyTaskIds = Set((destination.dailyTasks as? Set<DailyTaskEntity>)?.compactMap { $0.id } ?? [])
        let existingNpcNames = Set((destination.npcLike as? Set<NPCLikeEntity>)?.compactMap { $0.name } ?? [])
        let existingVillagersHouseNames = Set((destination.villagersHouse as? Set<VillagersHouseEntity>)?.compactMap { $0.name } ?? [])
        let existingVillagersLikeNames = Set((destination.villagersLike as? Set<VillagersLikeEntity>)?.compactMap { $0.name } ?? [])

        // 수집된 생물 이전 (중복 제외)
        if let critters = source.critters as? Set<ItemEntity> {
            for critter in critters {
                if let name = critter.name, !existingCritterNames.contains(name) {
                    critter.userColletion = destination
                }
            }
        }

        // 일일 작업 이전 (중복 제외)
        if let dailyTasks = source.dailyTasks as? Set<DailyTaskEntity> {
            for task in dailyTasks {
                if let id = task.id, !existingDailyTaskIds.contains(id) {
                    task.userCollection = destination
                }
            }
        }

        // 좋아하는 NPC 이전 (중복 제외)
        if let npcLikes = source.npcLike as? Set<NPCLikeEntity> {
            for npc in npcLikes {
                if let name = npc.name, !existingNpcNames.contains(name) {
                    npc.userCollection = destination
                }
            }
        }

        // 마을 주민 집 이전 (중복 제외)
        if let villagersHouse = source.villagersHouse as? Set<VillagersHouseEntity> {
            for villager in villagersHouse {
                if let name = villager.name, !existingVillagersHouseNames.contains(name) {
                    villager.userCollection = destination
                }
            }
        }

        // 좋아하는 주민 이전 (중복 제외)
        if let villagersLike = source.villagersLike as? Set<VillagersLikeEntity> {
            for villager in villagersLike {
                if let name = villager.name, !existingVillagersLikeNames.contains(name) {
                    villager.userCollection = destination
                }
            }
        }
    }
}

// MARK: - NSManagedObjectContext Extension

extension NSManagedObjectContext {

    /// 변경사항을 저장합니다.
    /// - Returns: 저장 성공 여부
    @discardableResult
    func saveContext() -> Bool {
        guard hasChanges else { return true }

        do {
            try save()
            return true
        } catch {
            let nsError = error as NSError
            logger.error("Failed to save context: \(nsError.localizedDescription), \(nsError.userInfo)")
            return false
        }
    }

    /// 변경사항을 저장합니다. 에러 발생 시 throw합니다.
    func saveContextOrThrow() throws {
        guard hasChanges else { return }
        try save()
    }
}

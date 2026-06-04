import XCTest
import CoreData
import RxSwift
@testable import ACNH_wiki

final class CoreDataStorageICloudResetTests: XCTestCase {

    /// 테스트마다 격리된 UserDefaults suite. `.standard`(실제 앱 suite)를 건드리지 않아
    /// 실기기에서 `make test`를 돌려도 production 앱의 known-user/recovery 플래그를 오염시키지 않는다.
    private var testSuiteName: String!
    private var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testSuiteName = "CoreDataStorageICloudResetTests.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: testSuiteName)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: testSuiteName)
        testDefaults = nil
        testSuiteName = nil
        super.tearDown()
    }

    func testRecoveryGraceDoesNotCreateEmptyUserCollectionForKnownUser() throws {
        let storage = try makeStorage()
        let context = storage.persistentContainer.viewContext

        let existingUserCollection = try insertUserCollection(in: context)
        try context.save()

        _ = try storage.getUserCollection(context)
        XCTAssertTrue(storage.hasEverHadUserCollection)

        context.delete(existingUserCollection)
        try context.save()
        storage.markRecoveryInitiated()

        XCTAssertThrowsError(try storage.getUserCollection(context)) { error in
            assertNotFound(error)
        }
        XCTAssertTrue(context.insertedObjects.isEmpty)
        XCTAssertEqual(try userCollectionCount(in: context), 0)
    }

    func testFirstImportTimeoutDoesNotCreateUserCollectionBeforeImportArrives() throws {
        let storage = try makeStorage()
        let context = storage.persistentContainer.viewContext

        storage.markWaitingForFirstImport()
        storage.completeFirstImportWait(reason: .timeout)

        XCTAssertThrowsError(try storage.getUserCollection(context)) { error in
            assertNotFound(error)
        }
        XCTAssertTrue(context.insertedObjects.isEmpty)
        XCTAssertEqual(try userCollectionCount(in: context), 0)
    }

    func testNoICloudPathStillAllowsFreshLocalUserCollection() throws {
        let storage = try makeStorage()
        let context = storage.persistentContainer.viewContext

        storage.markWaitingForFirstImport()
        storage.completeFirstImportWait(reason: .noICloud)

        let userCollection = try storage.getUserCollection(context)
        XCTAssertFalse(userCollection.isDeleted)
        XCTAssertEqual(context.insertedObjects.count, 1)
    }

    func testTimeoutAfterAlreadyObservedImportDoesNotKeepTimeoutSuppression() throws {
        let storage = try makeStorage()

        storage.lastSuccessfulImportDate = Date()
        storage.markWaitingForFirstImport()
        storage.completeFirstImportWait(reason: .timeout)

        XCTAssertFalse(storage.isFirstImportTimedOut)
        XCTAssertFalse(storage.shouldSuppressDataCreation)
    }

    func testAppFlowFetchTasksDuringRecoveryGraceDoesNotCreateEmptyLocalDataWithoutICloudAccount() throws {
        let storage = try makeStorage()
        let context = storage.persistentContainer.viewContext

        let existingUserCollection = try insertUserCollection(in: context)
        try context.save()

        _ = try storage.getUserCollection(context)
        XCTAssertTrue(storage.hasEverHadUserCollection)

        context.delete(existingUserCollection)
        try context.save()
        storage.markRecoveryInitiated()

        let result = waitForFetchTasks(using: CoreDataDailyTaskStorage(coreDataStorage: storage))

        assertReadErrorWrappingNotFound(result)
        XCTAssertEqual(try entityCount("UserCollectionEntity", in: storage), 0)
        XCTAssertEqual(try entityCount("DailyTaskEntity", in: storage), 0)
    }

    func testAppFlowFetchTasksAfterFirstImportTimeoutDoesNotCreateEmptyLocalDataWithoutICloudAccount() throws {
        let storage = try makeStorage()

        storage.markWaitingForFirstImport()
        storage.completeFirstImportWait(reason: .timeout)

        let result = waitForFetchTasks(using: CoreDataDailyTaskStorage(coreDataStorage: storage))

        assertReadErrorWrappingNotFound(result)
        XCTAssertEqual(try entityCount("UserCollectionEntity", in: storage), 0)
        XCTAssertEqual(try entityCount("DailyTaskEntity", in: storage), 0)
    }

    func testFailedCloudImportAfterTimeoutKeepsSuppressionAndDoesNotCreateEmptyData() throws {
        let storage = try makeStorage()

        storage.markWaitingForFirstImport()
        storage.completeFirstImportWait(reason: .timeout)
        storage.markImportInProgressForTesting()
        storage.finishCloudImportForTesting(succeeded: false)

        XCTAssertTrue(storage.isFirstImportTimedOut)
        XCTAssertFalse(storage.isImportInProgress)
        XCTAssertTrue(storage.shouldSuppressDataCreation)

        let result = waitForFetchTasks(using: CoreDataDailyTaskStorage(coreDataStorage: storage))

        assertReadErrorWrappingNotFound(result)
        XCTAssertEqual(try entityCount("UserCollectionEntity", in: storage), 0)
        XCTAssertEqual(try entityCount("DailyTaskEntity", in: storage), 0)
    }

    func testFailedCloudImportDuringSyncResetKeepsResetSuppressionAndDoesNotCreateEmptyData() throws {
        let storage = try makeStorage()

        storage.markSyncResetInProgressForTesting()
        storage.markImportInProgressForTesting()
        storage.finishCloudImportForTesting(succeeded: false)

        XCTAssertTrue(storage.isSyncResetInProgress)
        XCTAssertFalse(storage.isImportInProgress)
        XCTAssertTrue(storage.shouldSuppressDataCreation)

        let result = waitForFetchTasks(using: CoreDataDailyTaskStorage(coreDataStorage: storage))

        assertReadErrorWrappingNotFound(result)
        XCTAssertEqual(try entityCount("UserCollectionEntity", in: storage), 0)
        XCTAssertEqual(try entityCount("DailyTaskEntity", in: storage), 0)
    }

    func testSuccessfulCloudImportClearsResetAndTimeoutSuppression() throws {
        let storage = try makeStorage()

        storage.markWaitingForFirstImport()
        storage.completeFirstImportWait(reason: .timeout)
        storage.markSyncResetInProgressForTesting()
        storage.markImportInProgressForTesting()
        storage.finishCloudImportForTesting(succeeded: true)

        XCTAssertFalse(storage.isFirstImportTimedOut)
        XCTAssertFalse(storage.isImportInProgress)
        XCTAssertFalse(storage.isSyncResetInProgress)
    }

    func testTransientICloudAccountStatusesKeepFirstImportUnknown() {
        XCTAssertNil(SceneDelegate.firstImportWaitCompletionReason(for: .available))
        XCTAssertEqual(SceneDelegate.firstImportWaitCompletionReason(for: .noAccount), .noICloud)
        XCTAssertEqual(SceneDelegate.firstImportWaitCompletionReason(for: .restricted), .noICloud)
        XCTAssertEqual(SceneDelegate.firstImportWaitCompletionReason(for: .temporarilyUnavailable), .timeout)
        XCTAssertEqual(SceneDelegate.firstImportWaitCompletionReason(for: .couldNotDetermine), .timeout)
    }

    func testSafetySnapshotWriteUsesBackgroundSafeProtectionAndExcludesBackup() throws {
        let storage = try makeStorage()
        let context = storage.persistentContainer.viewContext
        try insertUserCollection(in: context)
        try context.save()

        let snapshotDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: snapshotDirectory) }
        var appliedProtection: FileProtectionType?
        let service = SafetySnapshotService(
            containerProvider: { storage.persistentContainer },
            snapshotDirectoryProvider: { snapshotDirectory },
            fileAttributeSetter: { _, attributes in
                appliedProtection = attributes[.protectionKey] as? FileProtectionType
            }
        )

        service.flushNow()

        XCTAssertTrue(FileManager.default.fileExists(atPath: service.snapshotURL.path))
        let resourceValues = try service.snapshotURL.resourceValues(forKeys: [.isExcludedFromBackupKey])
        XCTAssertEqual(resourceValues.isExcludedFromBackup, true)
        XCTAssertEqual(appliedProtection, .completeUntilFirstUserAuthentication)
    }

    func testSafetySnapshotRestoreFailureAfterWipeRollsBackExistingCollection() throws {
        enum InjectedRestoreFailure: Error {
            case failure
        }

        let storage = try makeStorage()
        let context = storage.persistentContainer.viewContext
        try insertUserCollection(in: context)
        try context.save()

        let snapshotDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: snapshotDirectory) }
        let snapshot = try UserCollectionSnapshot.dump(from: context)
        let snapshotURL = snapshotDirectory.appendingPathComponent("local_safety_snapshot.plist")
        try snapshot.toData().write(to: snapshotURL)

        let service = SafetySnapshotService(
            containerProvider: { storage.persistentContainer },
            snapshotDirectoryProvider: { snapshotDirectory }
        )
        service.beforeApplyingSnapshotForTesting = { _ in throw InjectedRestoreFailure.failure }

        let expectation = expectation(description: "restore completes")
        service.restore { outcome in
            guard case .failed(let error) = outcome else {
                XCTFail("Expected restore failure after injected error, got \(outcome)")
                expectation.fulfill()
                return
            }
            XCTAssertTrue(error is InjectedRestoreFailure)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)
        XCTAssertEqual(try entityCount("UserCollectionEntity", in: storage), 1)
    }

    func testAppFlowFetchTasksNoICloudFreshUserStillCreatesLocalDefaults() throws {
        let storage = try makeStorage()

        storage.markWaitingForFirstImport()
        storage.completeFirstImportWait(reason: .noICloud)

        let result = waitForFetchTasks(using: CoreDataDailyTaskStorage(coreDataStorage: storage))

        guard case .success(let tasks) = result else {
            XCTFail("Expected fetchTasks to succeed for no-iCloud fresh user, got \(result)")
            return
        }
        XCTAssertEqual(tasks.count, DailyTask.tasks.count)
        XCTAssertEqual(try entityCount("UserCollectionEntity", in: storage), 1)
        XCTAssertEqual(try entityCount("DailyTaskEntity", in: storage), DailyTask.tasks.count)
    }
}

// MARK: - Helpers

extension CoreDataStorageICloudResetTests {

    private func makeStorage() throws -> CoreDataStorage {
        let model = try makeManagedObjectModel()
        let container = NSPersistentCloudKitContainer(name: "CoreDataStorage", managedObjectModel: model)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]

        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }
        if let loadError {
            throw loadError
        }

        return CoreDataStorage(testingPersistentContainer: container, userDefaults: testDefaults)
    }

    private func makeManagedObjectModel() throws -> NSManagedObjectModel {
        let bundle = Bundle(for: CoreDataStorage.self)
        guard let modelURL = bundle.url(forResource: "CoreDataStorage", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            throw TestError.modelNotFound
        }
        return model
    }

    @discardableResult
    private func insertUserCollection(
        in context: NSManagedObjectContext,
        userInfo: UserInfo = UserInfo()
    ) throws -> UserCollectionEntity {
        guard let object = NSEntityDescription.insertNewObject(
            forEntityName: "UserCollectionEntity",
            into: context
        ) as? UserCollectionEntity else {
            throw TestError.entityCastFailed
        }
        object.name = userInfo.name
        object.islandName = userInfo.islandName
        object.islandFruit = userInfo.islandFruit.imageName
        object.hemisphere = userInfo.hemisphere.rawValue.capitalized
        object.islandReputation = Int16(userInfo.islandReputation)
        return object
    }

    private func userCollectionCount(in context: NSManagedObjectContext) throws -> Int {
        let request = UserCollectionEntity.fetchRequest()
        return try context.count(for: request)
    }

    private func entityCount(_ entityName: String, in storage: CoreDataStorage) throws -> Int {
        let context = storage.persistentContainer.newBackgroundContext()
        var count = 0
        var caughtError: Error?

        context.performAndWait {
            let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
            do {
                count = try context.count(for: request)
            } catch {
                caughtError = error
            }
        }

        if let caughtError {
            throw caughtError
        }
        return count
    }

    private func waitForFetchTasks(using storage: CoreDataDailyTaskStorage) -> Result<[DailyTask], Error> {
        let expectation = expectation(description: "fetchTasks")
        var result: Result<[DailyTask], Error>?

        let disposable = storage.fetchTasks().subscribe(
            onSuccess: { tasks in
                result = .success(tasks)
                expectation.fulfill()
            },
            onFailure: { error in
                result = .failure(error)
                expectation.fulfill()
            }
        )

        wait(for: [expectation], timeout: 10)
        disposable.dispose()
        return result ?? .failure(TestError.timeout)
    }

    private func assertNotFound(_ error: Error, file: StaticString = #filePath, line: UInt = #line) {
        guard case CoreDataStorageError.notFound = error else {
            XCTFail("Expected CoreDataStorageError.notFound, got \(error)", file: file, line: line)
            return
        }
    }

    private func assertReadErrorWrappingNotFound(
        _ result: Result<[DailyTask], Error>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .failure(let error) = result else {
            XCTFail("Expected fetchTasks to fail, got \(result)", file: file, line: line)
            return
        }
        guard case CoreDataStorageError.readError(let underlying) = error else {
            XCTFail("Expected CoreDataStorageError.readError, got \(error)", file: file, line: line)
            return
        }
        assertNotFound(underlying, file: file, line: line)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private enum TestError: Error {
        case modelNotFound
        case entityCastFailed
        case timeout
    }
}

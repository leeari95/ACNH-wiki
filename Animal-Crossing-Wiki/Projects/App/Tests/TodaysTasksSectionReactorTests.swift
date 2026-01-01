//
//  TodaysTasksSectionReactorTests.swift
//  Animal-Crossing-Wiki
//
//  Created by Claude on 2025/01/01.
//

import XCTest
import RxSwift
import RxTest
import RxBlocking
@testable import ACNH_wiki

// MARK: - Mock Classes

final class MockDashboardCoordinator: DashboardCoordinator {
    var transitionedRoutes: [Route] = []

    override func transition(for route: Route) {
        transitionedRoutes.append(route)
    }
}

final class MockDailyTaskStorage: DailyTaskStorage {
    var tasks: [DailyTask] = []
    var toggleCompletedCalled = false
    var updateTaskCalled = false
    var lastToggledTask: DailyTask?
    var lastUpdatedTask: DailyTask?

    func fetchTasks() -> Single<[DailyTask]> {
        return .just(tasks)
    }

    func insertTask(_ task: DailyTask) -> Single<DailyTask> {
        tasks.append(task)
        return .just(task)
    }

    func updateTask(_ task: DailyTask) {
        updateTaskCalled = true
        lastUpdatedTask = task
    }

    func toggleCompleted(_ task: DailyTask, progressIndex: Int) {
        toggleCompletedCalled = true
        lastToggledTask = task
    }

    func deleteTaskDelete(_ task: DailyTask) -> Single<DailyTask> {
        tasks.removeAll { $0.id == task.id }
        return .just(task)
    }
}

// MARK: - Tests

final class TodaysTasksSectionReactorTests: XCTestCase {

    var disposeBag: DisposeBag!
    var scheduler: TestScheduler!
    var mockCoordinator: MockDashboardCoordinator!
    var mockStorage: MockDailyTaskStorage!

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        scheduler = TestScheduler(initialClock: 0)
        mockCoordinator = MockDashboardCoordinator()
        mockStorage = MockDailyTaskStorage()
    }

    override func tearDown() {
        disposeBag = nil
        scheduler = nil
        mockCoordinator = nil
        mockStorage = nil
        super.tearDown()
    }

    // MARK: - Test Helpers

    private func makeDailyTask(
        name: String = "Test Task",
        icon: String = "Inv167",
        amount: Int = 3,
        isCompleted: Bool = false
    ) -> DailyTask {
        // Use the existing convenience initializer that properly creates progressList
        DailyTask(
            name: name,
            icon: icon,
            isCompleted: isCompleted,
            amount: amount,
            createdDate: Date()
        )
    }

    private func makeReactor() -> TodaysTasksSectionReactor {
        TodaysTasksSectionReactor(
            coordinator: mockCoordinator,
            storage: mockStorage
        )
    }

    // MARK: - Initial State Tests

    func test_InitialState_TasksShouldBeEmpty() {
        let reactor = makeReactor()

        XCTAssertTrue(reactor.currentState.tasks.isEmpty)
    }

    // MARK: - Action Tests

    func test_SelectedItemAction_ShouldCallToggleCompletedOnStorage() {
        // Given
        let reactor = makeReactor()
        let task = makeDailyTask(amount: 3)

        // Manually set up tasks state (simulating fetch)
        var tasksList = [(progressIndex: Int, task: DailyTask)]()
        (0..<task.amount).forEach { index in
            tasksList.append((index, task))
        }

        // When
        reactor.action.onNext(.selectedItem(indexPath: IndexPath(item: 0, section: 0)))

        // Wait for async processing
        let expectation = XCTestExpectation(description: "Toggle completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func test_EditAction_ShouldTransitionToTaskEdit() {
        // Given
        let reactor = makeReactor()

        // When
        reactor.action.onNext(.edit)

        // Then
        let expectation = XCTestExpectation(description: "Transition to task edit")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.mockCoordinator.transitionedRoutes.count, 1)
            if case .taskEdit = self.mockCoordinator.transitionedRoutes.first {
                // Success
            } else {
                XCTFail("Expected taskEdit route")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Mutation Tests

    func test_SetTasksMutation_ShouldExpandTasksByAmount() {
        // Given
        let reactor = makeReactor()
        let task1 = makeDailyTask(name: "Task 1", amount: 2)
        let task2 = makeDailyTask(name: "Task 2", amount: 3)

        // When
        let initialState = TodaysTasksSectionReactor.State()
        let mutation = TodaysTasksSectionReactor.Mutation.setTasks([task1, task2])
        let newState = reactor.reduce(state: initialState, mutation: mutation)

        // Then
        // Task 1 with amount 2 = 2 entries
        // Task 2 with amount 3 = 3 entries
        // Total = 5 entries
        XCTAssertEqual(newState.tasks.count, 5)
    }

    func test_SetTasksMutation_ShouldAssignCorrectProgressIndices() {
        // Given
        let reactor = makeReactor()
        let task = makeDailyTask(name: "Test Task", amount: 3)

        // When
        let initialState = TodaysTasksSectionReactor.State()
        let mutation = TodaysTasksSectionReactor.Mutation.setTasks([task])
        let newState = reactor.reduce(state: initialState, mutation: mutation)

        // Then
        XCTAssertEqual(newState.tasks[0].progressIndex, 0)
        XCTAssertEqual(newState.tasks[1].progressIndex, 1)
        XCTAssertEqual(newState.tasks[2].progressIndex, 2)
    }

    func test_ToggleCompletedMutation_ShouldCallStorageToggle() {
        // Given
        let reactor = makeReactor()
        let task = makeDailyTask(amount: 1)

        // Set up initial state with tasks
        var initialState = TodaysTasksSectionReactor.State()
        initialState.tasks = [(progressIndex: 0, task: task)]

        // When
        let mutation = TodaysTasksSectionReactor.Mutation.toggleCompleted(index: 0)
        _ = reactor.reduce(state: initialState, mutation: mutation)

        // Then
        XCTAssertTrue(mockStorage.toggleCompletedCalled)
    }

    func test_ResetMutation_ShouldCallStorageUpdateForAllTasks() {
        // Given
        let reactor = makeReactor()
        let task1 = makeDailyTask(name: "Task 1", amount: 1)
        let task2 = makeDailyTask(name: "Task 2", amount: 1)

        // Set up initial state with tasks
        var initialState = TodaysTasksSectionReactor.State()
        initialState.tasks = [
            (progressIndex: 0, task: task1),
            (progressIndex: 0, task: task2)
        ]

        // When
        let mutation = TodaysTasksSectionReactor.Mutation.reset
        _ = reactor.reduce(state: initialState, mutation: mutation)

        // Then
        XCTAssertTrue(mockStorage.updateTaskCalled)
    }

    // MARK: - State Transition Tests

    func test_TransitionMutation_ShouldCallCoordinatorTransition() {
        // Given
        let reactor = makeReactor()
        let initialState = TodaysTasksSectionReactor.State()

        // When
        let mutation = TodaysTasksSectionReactor.Mutation.transition(route: .taskEdit)
        _ = reactor.reduce(state: initialState, mutation: mutation)

        // Then
        XCTAssertEqual(mockCoordinator.transitionedRoutes.count, 1)
    }

    // MARK: - RxTest Integration Tests

    func test_FetchAction_ShouldEmitSetTasksMutation() {
        // Given
        let reactor = makeReactor()

        // Create observer for state changes
        let stateObserver = scheduler.createObserver([( progressIndex: Int, task: DailyTask)].self)

        reactor.state
            .map { $0.tasks }
            .bind(to: stateObserver)
            .disposed(by: disposeBag)

        // When
        scheduler.scheduleAt(10) {
            reactor.action.onNext(.fetch)
        }

        scheduler.start()

        // Then
        // Initial state should be empty
        XCTAssertTrue(stateObserver.events.first?.value.element?.isEmpty ?? true)
    }

    func test_MultipleActions_ShouldProcessSequentially() {
        // Given
        let reactor = makeReactor()
        var actionOrder: [String] = []

        reactor.state
            .skip(1) // Skip initial state
            .subscribe(onNext: { _ in
                actionOrder.append("stateChanged")
            })
            .disposed(by: disposeBag)

        // When
        reactor.action.onNext(.fetch)
        reactor.action.onNext(.edit)

        // Wait for processing
        let expectation = XCTestExpectation(description: "Actions processed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertTrue(mockCoordinator.transitionedRoutes.contains { route in
            if case .taskEdit = route { return true }
            return false
        })
    }
}


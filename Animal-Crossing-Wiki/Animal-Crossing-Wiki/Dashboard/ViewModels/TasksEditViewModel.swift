//
//  TasksEditViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/24.
//

import Foundation
import RxSwift
import RxRelay

final class TasksEditViewModel {
    
    private let storage: DailyTaskStorage
    private let coordinator: DashboardCoordinator
    
    init(coordinator: DashboardCoordinator, storage: DailyTaskStorage = CoreDataDailyTaskStorage()) {
        self.coordinator = coordinator
        self.storage = storage
    }
    
    private var tasks = [DailyTask]()
    
    struct Input {
        let didSeletedTask: Observable<DailyTask>
        let didTapCancel: Observable<Void>
        let didDeleted: Observable<IndexPath>
    }
    
    struct Output {
        let tasks: Observable<[DailyTask]>
    }
    
    func transform(input: Input, disposeBag: DisposeBag) -> Output {
        let currentTasks = BehaviorRelay<[DailyTask]>(value: [])
        
        Items.shared.dailyTasks
            .withUnretained(self)
            .subscribe(onNext: { owner, tasks in
                var tasks = tasks
                tasks.append(
                    DailyTask(
                        name: "Add a custom task",
                        icon: "plus",
                        isCompleted: false,
                        amount: 1,
                        createdDate: Date()
                    )
                )
                currentTasks.accept(tasks)
                owner.tasks = tasks
            }).disposed(by: disposeBag)
        
        input.didSeletedTask
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { task in
                self.coordinator.transition(for: .customTask(task: task))
            }).disposed(by: disposeBag)
        
        input.didTapCancel
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { _ in
                self.coordinator.transition(for: .dismiss)
            }).disposed(by: disposeBag)
        
        input.didDeleted
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .subscribe(onNext: { owner, indexPath in
                owner.storage.deleteTaskDelete(owner.tasks.remove(at: indexPath.row))
                    .subscribe(onSuccess: { task in
                        Items.shared.deleteTask(task)
                    }, onFailure: { error in
                        debugPrint(error)
                    }).disposed(by: disposeBag)
                currentTasks.accept(owner.tasks)
            }).disposed(by: disposeBag)
        
        return Output(tasks: currentTasks.asObservable())
    }
}

//
//  TodaysTasksSectionViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/24.
//

import Foundation
import RxSwift
import RxRelay

final class TodaysTasksSectionViewModel {
    
    var coordinator: DashboardCoordinator?
    
    init(coordinator: DashboardCoordinator?) {
        self.coordinator = coordinator
    }
    
    private let storage: CoreDataDailyTaskStorage = CoreDataDailyTaskStorage()
    
    private var tasks: [(progressIndex: Int, task: DailyTask)] = []
    
    struct Input {
        let didSelectItem: Observable<IndexPath>
        let didTapReset: Observable<Void>
        let didTapEdit: Observable<Void>
    }
    
    struct Output {
        let tasks: Observable<[(progressIndex: Int, task: DailyTask)]>
    }
    
    func transform(input: Input, disposeBag: DisposeBag) -> Output {
        let currentTasks = BehaviorRelay<[(progressIndex: Int, task: DailyTask)]>(value: [])
        
        Items.shared.dailyTasks
            .subscribe(onNext: { tasks in
                var tasksList = [(progressIndex: Int, task: DailyTask)]()
                tasks.forEach { task in
                    (0..<task.amount).forEach { index in
                        tasksList.append((index, task))
                    }
                }
                self.tasks = tasksList
                currentTasks.accept(tasksList)
            }).disposed(by: disposeBag)
        
        input.didSelectItem
            .compactMap { self.tasks[safe: $0.row] }
            .withUnretained(self)
            .subscribe(onNext: { owner, item in
                let progressIndex = item.progressIndex
                let task = item.task
                owner.storage.toggleCompleted(task, progressIndex: progressIndex)
            }).disposed(by: disposeBag)
        
        input.didTapReset
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.tasks.enumerated().forEach { (index, tuple) in
                    var tuple = tuple
                    tuple.task.reset()
                    owner.tasks[index] = tuple
                    owner.storage.updateTask(tuple.task)
                }
                currentTasks.accept(owner.tasks)
            }).disposed(by: disposeBag)
        
        input.didTapEdit
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.coordinator?.transition(for: .taskEdit)
            }).disposed(by: disposeBag)
        
        return Output(tasks: currentTasks.asObservable())
    }
}

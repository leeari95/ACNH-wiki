//
//  TodaysTasksSesctionViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/24.
//

import Foundation
import RxSwift
import RxRelay

final class TodaysTasksSesctionViewModel {
    
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
            .subscribe(onNext: { indexPath in
                let progressIndex = self.tasks[indexPath.row].progressIndex
                let task = self.tasks[indexPath.row].task
                self.storage.toggleCompleted(task, progressIndex: progressIndex)
            }).disposed(by: disposeBag)
        
        input.didTapReset
            .subscribe(onNext: { _ in
                self.tasks.enumerated().forEach { (index, tuple) in
                    var tuple = tuple
                    tuple.task.reset()
                    self.tasks[index] = tuple
                    self.storage.updateTask(tuple.task)
                }
                currentTasks.accept(self.tasks)
            }).disposed(by: disposeBag)
        
        input.didTapEdit
            .subscribe(onNext: { _ in
                self.coordinator?.presentToTaskEdit()
            }).disposed(by: disposeBag)
        
        return Output(tasks: currentTasks.asObservable())
    }
}

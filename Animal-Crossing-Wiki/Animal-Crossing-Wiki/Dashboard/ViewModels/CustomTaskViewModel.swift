//
//  CustomTaskViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/24.
//

import Foundation
import RxSwift
import RxRelay

final class CustomTaskViewModel {
    
    private let task: DailyTask?
    private let storage: CoreDataDailyTaskStorage = CoreDataDailyTaskStorage()
    private let coordinator: TasksEditCoordinator
    
    init(coordinator: TasksEditCoordinator, task: DailyTask?) {
        self.coordinator = coordinator
        self.task = task
    }
    
    struct Input {
        let didTapCheck: Observable<Void>?
        let didTapCancel: Observable<Void>?
        let didTapIcon: Observable<Void>
        let didTapAmount: Observable<Void>
        let taskNameText: Observable<String?>
        let iconNameText: Observable<String?>
        let amountText: Observable<String?>
    }
    
    struct Output {
        let task: Observable<DailyTask?>
    }
    
    func transform(input: Input, disposeBag: DisposeBag) -> Output {
        
        let title = BehaviorRelay<String?>(value: nil)
        let icon = BehaviorRelay<String?>(value: nil)
        let amount = BehaviorRelay<String?>(value: nil)
    
        input.didTapCancel?
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.coordinator.dismiss(animated: true)
        }).disposed(by: disposeBag)
        
        input.didTapCheck?
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                var newTask: DailyTask
                if let task = owner.task {
                    let amount = amount.value != nil ? Int(amount.value ?? "1") ?? 1 : task.amount
                    newTask = DailyTask(
                        id: task.id,
                        name: title.value ?? task.name,
                        icon: icon.value ?? task.icon,
                        progressList: Array(repeating: false, count: amount),
                        amount: amount,
                        createdDate: task.createdDate
                    )
                } else {
                    newTask = DailyTask(
                        name: title.value ?? "",
                        icon: icon.value ?? "Inv7",
                        isCompleted: false,
                        amount: Int(amount.value ?? "1") ?? 1,
                        createdDate: Date()
                    )
                }
                owner.storage.updateTask(newTask)
                Items.shared.updateTasks(newTask)
                owner.coordinator.rootViewController.visibleViewController.flatMap { owner.coordinator.dismiss($0) }
                
            }).disposed(by: disposeBag)
        
        input.didTapIcon
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.coordinator.presentToIcon()
            }).disposed(by: disposeBag)
        
        input.didTapAmount
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.coordinator.presentToAmount(
                    currentAmount: owner.task?.amount.description ?? "1",
                    disposeBag: disposeBag
                )
            }).disposed(by: disposeBag)
        
        input.taskNameText
            .filter { $0 != "" }
            .compactMap { $0 }
            .subscribe(onNext: { text in
                title.accept(text)
            }).disposed(by: disposeBag)
        
        input.iconNameText
            .subscribe(onNext: { text in
                icon.accept(text)
            }).disposed(by: disposeBag)
        
        input.amountText
            .subscribe(onNext: { text in
                amount.accept(text)
            }).disposed(by: disposeBag)
        
        return Output(task: Observable.just(task))
    }
}

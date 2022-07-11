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
    private let coordinator: DashboardCoordinator
    
    init(coordinator: DashboardCoordinator, task: DailyTask?) {
        self.coordinator = coordinator
        self.task = task
    }
    
    deinit {
        coordinator.delegate = nil
    }
    
    struct Input {
        let didTapCheck: Observable<Void>?
        let didTapIcon: Observable<Void>
        let didTapAmount: Observable<Void>
        let taskNameText: Observable<String?>
        let iconNameText: Observable<String?>
        let amountText: Observable<String?>
    }
    
    struct Output {
        let task: Observable<DailyTask?>
        let didChangeAmout: Observable<String>
    }
    
    func transform(input: Input, disposeBag: DisposeBag) -> Output {
        
        let title = BehaviorRelay<String?>(value: nil)
        let icon = BehaviorRelay<String?>(value: nil)
        let amount = BehaviorRelay<String?>(value: nil)
        let currentAmount = BehaviorRelay<String>(value: task?.amount.description ?? "1")
        
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
                owner.coordinator.transition(for: .pop)
            }).disposed(by: disposeBag)
        
        input.didTapIcon
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.coordinator.transition(for: .iconChooser)
            }).disposed(by: disposeBag)
        
        input.didTapAmount
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.coordinator.rootViewController.visibleViewController?
                    .showSeletedItemAlert(
                        Array(1...20).map { $0.description },
                        currentItem: currentAmount.value
                    ).subscribe(onNext: { title in
                        currentAmount.accept(title)
                    }).disposed(by: disposeBag)
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
        
        return Output(task: Observable.just(task), didChangeAmout: currentAmount.asObservable())
    }
}

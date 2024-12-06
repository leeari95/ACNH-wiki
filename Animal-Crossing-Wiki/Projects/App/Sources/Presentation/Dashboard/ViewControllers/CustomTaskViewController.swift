//
//  EditTaskViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/20.
//

import UIKit
import RxSwift
import RxRelay

final class CustomTaskViewController: UIViewController {

    enum Mode: String {
        case add = "New task"
        case edit = "Edit task"
    }

    var mode: Mode?

    private let currentIconName = BehaviorRelay<String?>(value: nil)
    private let currentAmount = BehaviorRelay<String?>(value: nil)
    private let currentTask = BehaviorRelay<DailyTask?>(value: nil)
    private let disposeBag = DisposeBag()

    private lazy var customTaskSection = CustomTaskView()
    private lazy var sectionsScrollView: SectionsScrollView = SectionsScrollView(
        SectionView(
            title: mode?.rawValue.localized ?? "",
            iconName: "highlighter",
            contentView: customTaskSection
        )
    )
    private lazy var doneButton: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .done, target: self, action: nil)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
    }

    private func setUpViews() {
        view.backgroundColor = .acBackground
        navigationItem.title = mode?.rawValue.localized
        navigationItem.largeTitleDisplayMode = .never

        navigationItem.rightBarButtonItem = doneButton
        navigationItem.rightBarButtonItem?.tintColor = .acNavigationBarTint

        view.addSubviews(sectionsScrollView)

        NSLayoutConstraint.activate([
            sectionsScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            sectionsScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            sectionsScrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            sectionsScrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }

    func bind(to reactor: CustomTaskReactor) {
        doneButton.rx.tap
            .map { CustomTaskReactor.Action.save }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        customTaskSection.iconButtonObservable
            .map { CustomTaskReactor.Action.iconList }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        currentIconName.compactMap { $0 }
            .map { CustomTaskReactor.Action.iconName($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        customTaskSection.maxAmountButtonObservable
            .flatMapLatest { [weak self] _ -> Observable<CustomTaskReactor.Action> in
                guard let owner = self else {
                    return .empty()
                }

                return owner.showSelectedItemAlert(
                    Array(1...20).map { $0.description },
                    currentItem: owner.currentAmount.value
                )
                .map { CustomTaskReactor.Action.amount($0) }
            }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            })
            .disposed(by: disposeBag)

        customTaskSection.taskNameObservable
            .map { CustomTaskReactor.Action.taskName($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        reactor.state
            .compactMap { $0.amount }
            .subscribe(with: self, onNext: { owner, amount in
                owner.customTaskSection.updateAmount(amount.description)
                owner.currentAmount.accept(amount.description)
            }).disposed(by: disposeBag)

        reactor.state.compactMap { $0.task }
            .filter { [weak self] in self?.currentTask.value != $0 }
            .subscribe(with: self, onNext: { owner, task in
                owner.customTaskSection.setUpViews(task)
                owner.currentAmount.accept(task.amount.description)
                owner.currentTask.accept(task)
            }).disposed(by: disposeBag)
    }

}

extension CustomTaskViewController: CustomTaskViewControllerDelegate {
    func selectedIcon(_ icon: String) {
        customTaskSection.updateIcon(icon)
        currentIconName.accept(icon)
    }
}

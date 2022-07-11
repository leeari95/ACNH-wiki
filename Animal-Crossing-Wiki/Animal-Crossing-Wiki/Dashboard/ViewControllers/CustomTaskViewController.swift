//
//  EditTaskViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/20.
//

import UIKit
import RxSwift
import RxRelay

class CustomTaskViewController: UIViewController {
    
    enum Mode: String {
        case add = "New task"
        case edit = "Edit task"
    }
    
    var mode: Mode?
    var viewModel: CustomTaskViewModel?

    private let iconText = BehaviorRelay<String?>(value: nil)
    private let amount = BehaviorRelay<String?>(value: nil)
    private let disposeBag = DisposeBag()
    
    private lazy var customTaskSection = CustomTaskView()
    private lazy var sectionsScrollView: SectionsScrollView = SectionsScrollView(
        SectionView(
            title: mode?.rawValue ?? "",
            iconName: "highlighter",
            contentView: customTaskSection
        )
    )
    private lazy var checkButton: UIBarButtonItem = {
        return .init(
            image: UIImage(systemName: "checkmark.circle"),
            style: .plain,
            target: self,
            action: nil
        )
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
    }
    
    private func setUpViews() {
        view.backgroundColor = .acBackground
        self.navigationItem.title = mode?.rawValue
        navigationItem.largeTitleDisplayMode = .never
        
        navigationItem.rightBarButtonItem = checkButton
        navigationItem.rightBarButtonItem?.tintColor = .acHeaderBackground

        view.addSubviews(sectionsScrollView)
        
        NSLayoutConstraint.activate([
            sectionsScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            sectionsScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            sectionsScrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            sectionsScrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
    
    func bind(to viewModel: CustomTaskViewModel) {
        let input = CustomTaskViewModel.Input(
            didTapCheck: checkButton.rx.tap.asObservable(),
            didTapIcon: customTaskSection.iconButtonObservable,
            didTapAmount: customTaskSection.maxAmountButtonObservable,
            taskNameText: customTaskSection.taskNameObservable,
            iconNameText: iconText.asObservable(),
            amountText: amount.asObservable()
        )
        let output = viewModel.transform(input: input, disposeBag: disposeBag)
        
        output.task
            .compactMap { $0 }
            .withUnretained(self)
            .subscribe(onNext: { owner, task in
                owner.customTaskSection.setUpViews(task)
            }).disposed(by: disposeBag)
        
        output.didChangeAmout
            .compactMap { $0 }
            .observe(on: MainScheduler.asyncInstance)
            .withUnretained(self)
            .subscribe(onNext: { owner, text in
                owner.customTaskSection.updateAmount(text)
                owner.amount.accept(text)
            }).disposed(by: disposeBag)
    }

}

extension CustomTaskViewController: CustomTaskViewControllerDelegate {
    func selectedIcon(_ icon: String) {
        customTaskSection.updateIcon(icon)
        iconText.accept(icon)
    }
}

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
    
    private lazy var customTaskSection = CustomTaskSection()
    private lazy var sectionsScrollView: SectionsScrollView = SectionsScrollView(
        SectionView(
            title: mode?.rawValue ?? "",
            iconName: "highlighter",
            contentView: customTaskSection
        )
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
        bind()
    }
    
    private func setUpView() {
        view.backgroundColor = .acBackground
        self.navigationItem.title = mode?.rawValue
        navigationItem.largeTitleDisplayMode = .never
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "checkmark"),
            style: .plain,
            target: self,
            action: nil
        )
        if mode == .add {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "xmark.app.fill"),
                style: .plain,
                target: self,
                action: nil
            )
        }
        
        view.addSubviews(sectionsScrollView)
        
        NSLayoutConstraint.activate([
            sectionsScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            sectionsScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            sectionsScrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            sectionsScrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
    
    private func bind() {
        let input = CustomTaskViewModel.Input(
            didTapCheck: navigationItem.rightBarButtonItem?.rx.tap.asObservable(),
            didTapCancel: navigationItem.leftBarButtonItem?.rx.tap.asObservable(),
            didTapIcon: self.customTaskSection.iconButtonObservable,
            didTapAmount: self.customTaskSection.maxAmountButtonObservable,
            taskNameText: self.customTaskSection.taskNameObservable,
            iconNameText: iconText.asObservable(),
            amountText: amount.asObservable()
        )
        let output = viewModel?.transform(input: input, disposeBag: disposeBag)
        
        output?.task
            .compactMap { $0 }
            .subscribe(onNext: { task in
                self.customTaskSection.setUpViews(task)
            }).disposed(by: disposeBag)
    }

}

extension CustomTaskViewController: CustomTaskViewControllerDelegate {
    func seletedIcon(_ icon: String) {
        customTaskSection.updateIcon(icon)
        iconText.accept(icon)
    }
    
    func updateAmount(title: String) {
        customTaskSection.updateAmount(title)
        amount.accept(title)
    }
}

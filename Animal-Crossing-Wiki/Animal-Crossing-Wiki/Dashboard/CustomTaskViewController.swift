//
//  EditTaskViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/20.
//

import UIKit
import RxSwift

class CustomTaskViewController: UIViewController {
    
    var task: DailyTask?
    var coordinator: TasksEditCoordinator?

    private let disposeBag = DisposeBag()
    
    private lazy var customTaskSection = CustomTaskSection(task)
    private lazy var sectionsScrollView: SectionsScrollView = SectionsScrollView(
        SectionView(title: "New task", iconName: "highlighter", contentView: customTaskSection)
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
    }
    
    deinit {
        coordinator = nil
    }
    
    private func setUpView() {
        view.backgroundColor = .acBackground
        self.navigationItem.title = "Edit Task"
        navigationItem.largeTitleDisplayMode = .never
        if task == nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "xmark.app.fill"),
                style: .plain,
                target: self,
                action: #selector(didTapCancelButton(_:))
            )
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "checkmark"),
            style: .plain,
            target: self,
            action: #selector(didTapCheckButton(_:))
        )
        
        view.addSubviews(sectionsScrollView)
        
        NSLayoutConstraint.activate([
            sectionsScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            sectionsScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            sectionsScrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            sectionsScrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
        
        customTaskSection.addTargets(self, icon: #selector(didTapIcon(_:)), maxAmount: #selector(didTapMaxAmount(_:)))
    }
    
    @objc private func didTapCancelButton(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @objc private func didTapCheckButton(_ sender: UIBarButtonItem) {
        coordinator?.dismiss(self)
    }
    
    @objc private func didTapMaxAmount(_ sender: UIButton) {
        showSeletedItemAlert(
            Array(1...20).map { $0.description },
            currentItem: sender.titleLabel?.text ?? ""
        ).subscribe(onNext: { title in
            self.customTaskSection.updateAmount(title)
        }).disposed(by: disposeBag)
    }
    
    @objc private func didTapIcon(_ sender: UIButton) {
        coordinator?.presentToIcon()
    }

}

extension CustomTaskViewController: CustomTaskViewControllerDelegate {
    func seletedIcon(_ icon: String) {
        customTaskSection.updateIcon(icon)
    }
}

//
//  TasksEditViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/17.
//

import UIKit
import RxSwift

class TaskEditViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .clear
        return tableView
    }()
    
    private lazy var cancelButton: UIBarButtonItem = {
        return .init(
            image: UIImage(systemName: "xmark.app.fill"),
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
        self.navigationItem.title = "Today's Tasks"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = cancelButton
        
        view.addSubviews(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
    
    func bind(to viewModel: TasksEditViewModel) {
        let input = TasksEditViewModel.Input(
            didSeletedTask: tableView.rx.modelSelected(DailyTask.self).asObservable(),
            didTapCancel: cancelButton.rx.tap.asObservable(),
            didDeleted: tableView.rx.itemDeleted.asObservable()
        )
        let output = viewModel.transform(input: input, disposeBag: disposeBag)
        
        output.tasks
            .bind(to: tableView.rx.items) { _, _, task in
                let cell = UITableViewCell()
                var content = cell.defaultContentConfiguration()
                if task.icon == "plus" {
                    content.image = UIImage(systemName: "plus")
                    content.textProperties.color = .systemBlue
                    content.textProperties.font = .preferredFont(forTextStyle: .callout)
                } else {
                    content.textProperties.color = .acText
                    content.image = UIImage(named: task.icon)
                    content.textProperties.font = .preferredFont(for: .callout, weight: .semibold)
                }
                content.imageProperties.maximumSize = CGSize(width: 35, height: 35)
                content.text = task.name
                cell.backgroundColor = .acSecondaryBackground
                cell.contentConfiguration = content
                cell.accessoryType = .disclosureIndicator
                cell.selectedBackgroundView = UIView()
                cell.selectedBackgroundView?.backgroundColor = .acText.withAlphaComponent(0.3)
                return cell
            }.disposed(by: disposeBag)
        
        tableView.rx.itemSelected
            .withUnretained(self)
            .subscribe(onNext: { owner, indexPath in
                owner.tableView.deselectRow(at: indexPath, animated: true)
            }).disposed(by: disposeBag)
    }

}

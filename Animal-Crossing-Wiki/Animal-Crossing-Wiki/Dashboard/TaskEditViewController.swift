//
//  TasksEditViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/17.
//

import UIKit
import RxSwift

class TaskEditViewController: UIViewController {
    
    var viewModel: TasksEditViewModel?
    private let disposeBag = DisposeBag()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .clear
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        bind()
    }
    
    private func setUp() {
        view.backgroundColor = .acBackground
        self.navigationItem.title = "Today's Tasks"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark.app.fill"),
            style: .plain,
            target: self,
            action: nil
        )
        
        view.addSubviews(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
    
    private func bind() {
        let input = TasksEditViewModel.Input(
            didSeletedTask: tableView.rx.modelSelected(DailyTask.self).asObservable(),
            didTapCancel: navigationItem.leftBarButtonItem?.rx.tap.asObservable(),
            didDeleted: tableView.rx.itemDeleted.asObservable()
        )
        let output = viewModel?.transform(input: input, disposeBag: disposeBag)
        
        output?.tasks
            .bind(to: tableView.rx.items) { _, _, task in
                let cell = UITableViewCell()
                var content = cell.defaultContentConfiguration()
                if task.icon == "plus" {
                    content.image = UIImage(systemName: "plus")
                    content.textProperties.color = .systemBlue
                    content.textProperties.font = .preferredFont(forTextStyle: .callout)
                } else {
                    content.textProperties.color = .acText
                    content.image = UIImage(named: task.icon)?.resizedImage(Size: CGSize(width: 30, height: 30))
                    content.textProperties.font = .preferredFont(for: .callout, weight: .semibold)
                }
                content.imageToTextPadding = 5
                content.text = task.name
                cell.backgroundColor = .acSecondaryBackground
                cell.contentConfiguration = content
                cell.accessoryType = .disclosureIndicator
                cell.selectedBackgroundView = UIView()
                cell.selectedBackgroundView?.backgroundColor = .acText.withAlphaComponent(0.3)
                return cell
            }.disposed(by: disposeBag)
        
        tableView.rx.itemSelected
            .subscribe(onNext: { indexPath in
                self.tableView.deselectRow(at: indexPath, animated: true)
            }).disposed(by: disposeBag)
    }

}

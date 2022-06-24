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
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: nil
        )
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
            didSeletedTask: tableView.rx.itemSelected.asObservable(),
            didTapCancel: navigationItem.leftBarButtonItem?.rx.tap.asObservable(),
            didTapAdd: navigationItem.rightBarButtonItem?.rx.tap.asObservable()
        )
        let output = viewModel?.transform(input: input, disposeBag: disposeBag)
        
        output?.tasks
            .bind(to: tableView.rx.items) { _, _, task in
                let cell = UITableViewCell()
                var content = cell.defaultContentConfiguration()
                content.image = UIImage(named: task.icon)?.resizedImage(Size: CGSize(width: 30, height: 30))
                content.imageToTextPadding = 5
                content.text = task.name
                content.textProperties.color = .acText
                content.textProperties.font = .preferredFont(for: .callout, weight: .semibold)
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

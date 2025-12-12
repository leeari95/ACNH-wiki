//
//  TasksEditViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/17.
//

import UIKit
import RxSwift

final class TaskEditViewController: UIViewController {

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
        navigationItem.title = "Today's Tasks".localized
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = cancelButton

        view.addSubviews(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }

    func bind(to reactor: TasksEditReactor) {
        self.rx.viewDidLoad
            .map { TasksEditReactor.Action.fetch }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)

        tableView.rx.modelSelected(DailyTask.self)
            .map { TasksEditReactor.Action.selectedTask($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        cancelButton.rx.tap
            .map { TasksEditReactor.Action.cancel }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        tableView.rx.itemDeleted
            .map { TasksEditReactor.Action.deleted(index: $0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        reactor.state.map { $0.tasks }
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
                content.text = task.name.localized
                cell.backgroundColor = .acSecondaryBackground
                cell.contentConfiguration = content
                cell.accessoryType = .disclosureIndicator
                cell.selectedBackgroundView = UIView()
                cell.selectedBackgroundView?.backgroundColor = .acText.withAlphaComponent(0.3)
                return cell
            }.disposed(by: disposeBag)

        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                self?.tableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: disposeBag)
    }

}

//
//  TasksEditViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/17.
//

import UIKit

class TaskEditViewController: UIViewController {
    
    weak var coordinator: TasksEditCoordinator?
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear

        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
    }
    
    private func setUp() {
        view.backgroundColor = .acBackground
        self.navigationItem.title = "Today's Tasks"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(didTapAddButton(_:))
        )
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark.app.fill"),
            style: .plain,
            target: self,
            action: #selector(didTapCancelButton(_:))
        )
        
        view.addSubviews(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
    
    @objc private func didTapCancelButton(_ sender: UIBarButtonItem) {
        dismiss(animated: true) {
            self.coordinator?.finish()
        }
    }
    
    @objc private func didTapAddButton(_ sender: UIBarButtonItem) {
        coordinator?.presentToAddTask()
    }

}

extension TaskEditViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DailyTask.tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let item = DailyTask.tasks[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.image = UIImage(named: item.icon)?.resizedImage(Size: CGSize(width: 30, height: 30))
        content.imageToTextPadding = 5
        content.text = item.name
        content.textProperties.color = .acText
        content.textProperties.font = .preferredFont(for: .callout, weight: .semibold)
        cell.backgroundColor = .acSecondaryBackground
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        cell.selectedBackgroundView = UIView()
        cell.selectedBackgroundView?.backgroundColor = .acText.withAlphaComponent(0.3)
        return cell
    }
}

extension TaskEditViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        coordinator?.pushToEditTask(DailyTask.tasks[indexPath.row])
    }
}

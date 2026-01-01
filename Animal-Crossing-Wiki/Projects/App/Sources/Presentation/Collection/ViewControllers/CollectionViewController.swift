//
//  CollectionViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/10.
//

import UIKit
import RxSwift

final class CollectionViewController: UIViewController {

    private let disposeBag = DisposeBag()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .clear
        tableView.contentInset.bottom = 60
        tableView.registerNib(CategoryRow.self)
        return tableView
    }()

    private lazy var emptyView: EmptyView = EmptyView(
        title: "There are no collectibles.".localized,
        description: "when you check some items, they'll be displayed here.".localized
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
    }

    private func setUpViews() {
        view.backgroundColor = .acBackground
        view.addSubviews(tableView, emptyView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setUpNavigationItem() {
        navigationItem.title = "collection".localized
    }

    func bind(to reactor: CollectionReactor) {
        setUpNavigationItem()

        self.rx.viewDidLoad
            .map { CollectionReactor.Action.fetch }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)

        tableView.rx.modelSelected((title: Category, count: Int).self)
            .map { CollectionReactor.Action.selectedCategory(title: $0.title) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        reactor.state.map { $0.catagories }
            .bind(to: tableView.rx.items(cellIdentifier: CategoryRow.className, cellType: CategoryRow.self)) { _, item, cell in
                cell.setUp(
                    iconName: item.title.iconName,
                    title: item.title.rawValue.localized,
                    itemCount: item.count
                )
            }.disposed(by: disposeBag)

        reactor.state.map { $0.catagories }
            .map { !$0.isEmpty }
            .bind(to: emptyView.rx.isHidden)
            .disposed(by: disposeBag)

        tableView.rx.itemSelected
            .subscribe(with: self, onNext: { owner, indexPath in
                owner.tableView.deselectRow(at: indexPath, animated: true)
            }).disposed(by: disposeBag)
    }
}

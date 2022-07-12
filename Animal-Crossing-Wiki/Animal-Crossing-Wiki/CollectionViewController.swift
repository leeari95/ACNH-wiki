//
//  CollectionViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/10.
//

import UIKit
import RxSwift

class CollectionViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .clear
        tableView.registerNib(CategoryRow.self)
        return tableView
    }()
    
    private lazy var progressButton: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "list.bullet"),
            style: .plain,
            target: self,
            action: nil
        )
        return barButtonItem
    }()
    
    private lazy var emptyView: UIStackView = {
        let stackView = UIStackView(axis: .vertical, alignment: .center, distribution: .fill, spacing: 8)
        let titleLabel = UILabel(
            text: "There are no collectibles.".localized,
            font: .preferredFont(for: .body, weight: .semibold),
            color: .acText.withAlphaComponent(0.7)
        )
        let subTitleLabel = UILabel(
            text: "when you check some items, they'll be displayed here.".localized,
            font: .preferredFont(forTextStyle: .footnote),
            color: .acText.withAlphaComponent(0.7)
        )
        stackView.addArrangedSubviews(titleLabel, subTitleLabel)
        return stackView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
    }
    
    private func setUpViews() {
        view.backgroundColor = .acBackground
        view.addSubviews(tableView, emptyView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setUpNavigationItem() {
        navigationItem.title = "Collection".localized
        self.navigationItem.rightBarButtonItem = progressButton
    }
    
    func bind(to viewModel: CollectionViewModel) {
        setUpNavigationItem()
        let input = CollectionViewModel.Input(
            selectedCategory: tableView.rx.modelSelected((title: Category, count: Int).self).asObservable(),
            didTapRightBarButton: progressButton.rx.tap.asObservable()
        )
        let output = viewModel.transform(input: input, disposeBag: disposeBag)
        
        output.catagories
            .bind(to: tableView.rx.items(cellIdentifier: CategoryRow.className, cellType: CategoryRow.self)) { _, item, cell in
                cell.setUp(
                    iconName: item.title.iconName,
                    title: item.title.rawValue.localized,
                    itemCount: item.count
                )
            }.disposed(by: disposeBag)
        
        output.catagories
            .map { !$0.isEmpty }
            .bind(to: emptyView.rx.isHidden)
            .disposed(by: disposeBag)

        tableView.rx.itemSelected
            .subscribe(onNext: { indexPath in
                self.tableView.deselectRow(at: indexPath, animated: true)
            }).disposed(by: disposeBag)
    }
}

//
//  CatalogViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/04.
//

import UIKit
import RxSwift

class CatalogViewController: UIViewController {
    
    private let disposeBag = DisposeBag()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .clear
        tableView.registerNib(CategoryRow.self)
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
    }
    
    private func setUpNavigationItem() {
        view.backgroundColor = .acBackground
        navigationItem.title = "Catalog"
    }
    
    private func setUpViews() {
        setUpNavigationItem()
        view.addSubviews(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
    
    func bind(to viewModel: CatalogViewModel) {
        let input = CatalogViewModel.Input(
            selectedCategory: tableView.rx.modelSelected((title: Category, count: Int).self).asObservable()
        )
        let output = viewModel.transform(input: input, disposeBag: disposeBag)
        
        output.catagories
            .bind(to: tableView.rx.items(cellIdentifier: CategoryRow.className, cellType: CategoryRow.self)) { _, item, cell in
                cell.setUp(
                    iconName: item.title.iconName,
                    title: item.title.rawValue,
                    itemCount: item.count
                )
            }.disposed(by: disposeBag)
        
        tableView.rx.itemSelected
            .withUnretained(self)
            .subscribe(onNext: { owner, indexPath in
                owner.tableView.deselectRow(at: indexPath, animated: true)
            }).disposed(by: disposeBag)
    }
}

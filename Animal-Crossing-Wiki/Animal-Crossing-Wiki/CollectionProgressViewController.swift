//
//  CollectionProgressViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/10.
//

import UIKit
import RxSwift

class CollectionProgressViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .clear
        tableView.registerNib(ItemProgressRow.self)
        return tableView
    }()
    
    private lazy var cancelButton: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark.app.fill"),
            style: .plain,
            target: self,
            action: nil
        )
        return barButtonItem
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
    }
    
    private func setUpViews() {
        view.backgroundColor = .acBackground
        setUpNavigationItem()
        view.addSubviews(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
    
    private func setUpNavigationItem() {
        navigationItem.title = "Collection Progress".localized
        if navigationController?.viewControllers.count == 1 {
            navigationItem.leftBarButtonItem = cancelButton
        }
    }
    
    func bind(to viewModel: CollectionProgressViewModel) {
        let input = CollectionProgressViewModel.Input(
            selectedCategory: tableView.rx.modelSelected(Category.self).asObservable(),
            didTapCancel: cancelButton.rx.tap.asObservable()
        )
        let output = viewModel.transform(input: input, disposeBag: disposeBag)
        
        output.items
            .bind(to: tableView.rx.items(cellIdentifier: ItemProgressRow.className, cellType: ItemProgressRow.self)) { _, category, cell in
                cell.setUp(for: category)
            }.disposed(by: disposeBag)
        
        tableView.rx.itemSelected
            .withUnretained(self)
            .subscribe(onNext: { owner, indexPath in
                owner.tableView.deselectRow(at: indexPath, animated: true)
            }).disposed(by: disposeBag)
    }
}

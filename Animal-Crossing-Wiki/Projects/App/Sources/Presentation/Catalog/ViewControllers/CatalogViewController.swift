//
//  CatalogViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/04.
//

import UIKit
import RxSwift
import ACNHCore
import ACNHShared

final class CatalogViewController: UIViewController {

    let mode: CatalogReactor.Mode
    private let disposeBag = DisposeBag()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .clear
        tableView.registerNib(CategoryRow.self)
        tableView.contentInsetAdjustmentBehavior = .always
        tableView.contentInset.bottom = 60
        return tableView
    }()

    private lazy var activityIndicator: LoadingView = {
        let activityIndicator = LoadingView(backgroundColor: .acBackground, alpha: 0.5)
        view.addSubviews(activityIndicator)
        activityIndicator.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        activityIndicator.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        return activityIndicator
    }()

    private lazy var searchButton: UIButton = {
        let button = UIButton()
        button.tintColor = .acText
        let config = UIImage.SymbolConfiguration(scale: .large)
        button.setImage(
            UIImage(systemName: "magnifyingglass.circle.fill", withConfiguration: config),
            for: .normal
        )
        return button
    }()
    
    init(mode: CatalogReactor.Mode) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        navigationController?.navigationBar.sizeToFit()
    }

    private func setUpNavigationItem() {
        view.backgroundColor = .acBackground
        navigationItem.title = (mode == .item ? "Catalog" : "animals").localized
        if mode == .item {
            let checkBarButton = UIBarButtonItem(customView: searchButton)
            navigationItem.rightBarButtonItems = [checkBarButton]
        }
    }

    private func setUpViews() {
        setUpNavigationItem()
        view.addSubviews(tableView)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
    }

    func bind(to reactor: CatalogReactor) {
        self.rx.viewDidLoad
            .map { CatalogReactor.Action.fetch }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)

        tableView.rx.modelSelected((title: Category, count: Int).self)
            .map { CatalogReactor.Action.selectedCategory(title: $0.0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        searchButton.rx.tap
            .map { CatalogReactor.Action.searchButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        reactor.state.map { $0.isLoading }
            .bind(to: activityIndicator.rx.isAnimating)
            .disposed(by: disposeBag)

        reactor.state.map { $0.categories }
            .bind(to: tableView.rx.items(cellIdentifier: CategoryRow.className, cellType: CategoryRow.self)) { _, item, cell in
                cell.setUp(
                    iconName: item.title.iconName,
                    title: item.title.rawValue.localized,
                    itemCount: item.count
                )
            }.disposed(by: disposeBag)
    }
}

//
//  ItemsViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/05.
//

import UIKit
import RxSwift

class ItemsViewController: UIViewController {
    enum SearchScope: String {
        case all = "All"
        case collection = "Collection"
    }
    
    var viewModel: ItemsViewModel?
    private let disposeBag = DisposeBag()

    private lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 100, height: 175)
        flowLayout.sectionInset = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        flowLayout.minimumLineSpacing = 25
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.registerNib(CatalogRow.self)
        return collectionView
    }()
    
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.placeholder = "Search..."
        searchController.searchBar.showsScopeBar = true
        searchController.searchBar.scopeButtonTitles = [
            SearchScope.all.rawValue,
            SearchScope.collection.rawValue
        ]
        return searchController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        bind()
    }
    
    private func setUpViews() {
        view.backgroundColor = .acBackground
        view.addSubviews(collectionView)
        NSLayoutConstraint.activate([
            collectionView.heightAnchor.constraint(equalTo: view.heightAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
        setUpNavigationItem()
        setUpSearchController()
    }
    
    private func setUpNavigationItem() {
        let moreButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.up.arrow.down.circle"),
            style: .plain,
            target: self,
            action: nil
        )
        moreButton.tintColor = .acNavigationBarTint
        self.navigationItem.rightBarButtonItem = moreButton
    }

    private func setUpSearchController() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func bind() {
        let input = ItemsViewModel.Input()
        let output = viewModel?.transform(input: input, disposeBag: disposeBag)
        
        output?.items
            .bind(to: collectionView.rx.items(cellIdentifier: CatalogRow.className, cellType: CatalogRow.self)) { _, item, cell in
                cell.setUp(item)
            }.disposed(by: disposeBag)
        
        output?.category
            .map { $0.rawValue }
            .bind(to: navigationItem.rx.title)
            .disposed(by: disposeBag)
    }
}

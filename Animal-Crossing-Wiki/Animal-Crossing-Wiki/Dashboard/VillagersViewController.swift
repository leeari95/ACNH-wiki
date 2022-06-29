//
//  VillagersViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/29.
//

import UIKit
import RxSwift

class VillagersViewController: UIViewController {

    var viewModel: VillagersViewModel?
    private let disposeBag = DisposeBag()
    
    private lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 100, height: 140)
        flowLayout.sectionInset = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        flowLayout.minimumLineSpacing = 25
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.registerNib(VillagersRow.self)
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        setUpViews()
    }
    
    private func bind() {
        let input = VillagersViewModel.Input()
        let output = viewModel?.transform(input: input, disposeBag: disposeBag)
        
        output?.villagers
            .bind(to: collectionView.rx.items(cellIdentifier: VillagersRow.className, cellType: VillagersRow.self)) { _, villager, cell in
                cell.setUp(villager)
            }.disposed(by: disposeBag)
    }
    
    private func setUpViews() {
        view.backgroundColor = .acBackground
        setUpNavigationItem()
        view.addSubviews(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
    
    private func setUpNavigationItem() {
        self.navigationItem.title = "Villagers"
        let moreButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.up.arrow.down.circle"),
            style: .plain,
            target: self,
            action: nil
        )
        moreButton.tintColor = .acHeaderBackground
        self.navigationItem.rightBarButtonItem = moreButton
        setUpSearchController()
    }

    private func setUpSearchController() {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = "Search a villager"
        searchController.searchBar.scopeButtonTitles = [
            "All",
            "Liked",
            "Residents"
        ]
        navigationItem.searchController = searchController
        searchController.searchBar.showsScopeBar = true
        searchController.hidesNavigationBarDuringPresentation = false
        navigationItem.hidesSearchBarWhenScrolling = false
    }

}

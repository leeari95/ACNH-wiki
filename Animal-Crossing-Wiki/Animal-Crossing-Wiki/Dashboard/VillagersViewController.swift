//
//  VillagersViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/29.
//

import UIKit
import RxSwift
import RxRelay

class VillagersViewController: UIViewController {

    var viewModel: VillagersViewModel?
    private let disposeBag = DisposeBag()
    private var currentSelected = ["All": "전체"]
    private var selectedKeyword = BehaviorRelay<[String: String]>(value: ["All": "전체"])
    
    private var menuItems: [(title: String, subTitle: [String])] = [
        ("Personality", Personality.allCases.map { $0.rawValue }),
        ("Gender", Gender.allCases.map { $0.rawValue }),
        ("Type", Subtype.allCases.map { $0.rawValue }),
        ("Species", Specie.allCases.map { $0.rawValue })
    ]
    
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
    
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.showsScopeBar = true
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.placeholder = "Search a villager"
        searchController.searchBar.scopeButtonTitles = [
            "All",
            "Liked",
            "Residents"
        ]
        return searchController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        setUpViews()
    }
    
    private func bind() {
        let input = VillagersViewModel.Input(
            searchBarText: searchController.searchBar.rx.text.asObservable(),
            seletedScopeButton: searchController.searchBar.rx.selectedScopeButtonIndex
                .compactMap { self.searchController.searchBar.scopeButtonTitles?[$0] },
            didSelectedMenuKeyword: selectedKeyword.asObservable()
        )
        let output = viewModel?.transform(input: input, disposeBag: disposeBag)
        
        output?.villagers
            .bind(to: collectionView.rx.items(cellIdentifier: VillagersRow.className, cellType: VillagersRow.self)) { _, villager, cell in
                cell.setUp(villager)
            }.disposed(by: disposeBag)
        
        searchController.searchBar.rx.selectedScopeButtonIndex
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { _ in
                self.searchController.searchBar.endEditing(true)
                self.selectedKeyword.accept(self.currentSelected)
            }).disposed(by: disposeBag)
    }
    
    private func setUpViews() {
        view.backgroundColor = .acBackground
        setUpNavigationItem()
        setUpSearchController()
        view.addSubviews(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 88),
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
        self.navigationItem.rightBarButtonItem?.menu = createFilterMenu()
    }

    private func setUpSearchController() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func createFilterMenu() -> UIMenu {
        let actionHandler: (UIAction) -> Void = { action in
            for menuItem in self.menuItems where menuItem.subTitle.contains(action.title) {
                self.currentSelected[menuItem.title] = action.title
            }
            self.currentSelected["All"] = nil
            self.navigationItem.rightBarButtonItem?.menu = self.createFilterMenu()
        }
        let items: [UIMenu] = menuItems
            .map { UIMenu(title: $0.title, subTitles: $0.subTitle, actionHandler: actionHandler) }
        items.forEach { menu in
            menu.children.forEach { element in
                let action = element as? UIAction
                if currentSelected[menu.title]?.contains(action?.title ?? "") == true {
                    action?.state = .on
                    action?.attributes = .disabled
                }
            }
        }
        
        let all = UIAction(title: "전체", handler: { _ in
            self.currentSelected = ["All": "전체"]
            self.navigationItem.rightBarButtonItem?.menu = self.createFilterMenu()
        })
        if currentSelected["All"] == "전체" {
            all.state = .on
            all.attributes = .disabled
        }
        selectedKeyword.accept(currentSelected)
        
        return UIMenu(title: "", options: .displayInline, children: [all] + items)
    }
}

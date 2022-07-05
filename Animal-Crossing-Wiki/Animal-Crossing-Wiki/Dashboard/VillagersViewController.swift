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
    enum Menu: String {
        case all = "All"
        case personality = "Personality"
        case gender = "Gender"
        case type = "Type"
        case species = "Species"
    }
    
    enum SearchScope: String {
        case all = "All"
        case liked = "Liked"
        case residents = "Residents"
    }

    var viewModel: VillagersViewModel?
    private let disposeBag = DisposeBag()
    private var currentSelected: [Menu: String] = [.all: Menu.all.rawValue]
    private var selectedKeyword = BehaviorRelay<[Menu: String]>(value: [.all: Menu.all.rawValue])
    
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
            SearchScope.all.rawValue,
            SearchScope.liked.rawValue,
            SearchScope.residents.rawValue
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
            selectedScopeButton: searchController.searchBar.rx.selectedScopeButtonIndex
                .compactMap { self.searchController.searchBar.scopeButtonTitles?[$0] },
            didSelectedMenuKeyword: selectedKeyword.asObservable(),
            villagerSelected: collectionView.rx.itemSelected.asObservable()
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
        moreButton.tintColor = .acNavigationBarTint
        self.navigationItem.rightBarButtonItem = moreButton
        self.navigationItem.rightBarButtonItem?.menu = createFilterMenu()
    }

    private func setUpSearchController() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func createFilterMenu() -> UIMenu {
        let menuItems: [(title: String, subTitle: [String])] = [
            (Menu.personality.rawValue, Personality.allCases.map { $0.rawValue }),
            (Menu.gender.rawValue, Gender.allCases.map { $0.rawValue }),
            (Menu.type.rawValue, Subtype.allCases.map { $0.rawValue }),
            (Menu.species.rawValue, Specie.allCases.map { $0.rawValue })
        ]
        
        let actionHandler: (UIAction) -> Void = { action in
            for menuItem in menuItems where menuItem.subTitle.contains(action.title) {
                let menu = Menu(rawValue: menuItem.title) ?? .all
                self.currentSelected[menu] = action.title
            }
            self.currentSelected[Menu.all] = nil
            self.navigationItem.rightBarButtonItem?.menu = self.createFilterMenu()
        }
        let items: [UIMenu] = menuItems
            .map { UIMenu(title: $0.title, subTitles: $0.subTitle, actionHandler: actionHandler) }
        items.forEach { menu in
            menu.children.forEach { element in
                let action = element as? UIAction
                let menu = Menu(rawValue: menu.title) ?? .all
                if currentSelected[menu]?.contains(action?.title ?? "") == true {
                    action?.state = .on
                    action?.attributes = .disabled
                }
            }
        }
        
        let all = UIAction(title: Menu.all.rawValue, handler: { _ in
            self.currentSelected = [Menu.all: Menu.all.rawValue]
            self.navigationItem.rightBarButtonItem?.menu = self.createFilterMenu()
        })
        if currentSelected[Menu.all] != nil {
            all.state = .on
            all.attributes = .disabled
        }
        selectedKeyword.accept(currentSelected)
        
        return UIMenu(title: "", options: .displayInline, children: [all] + items)
    }
}

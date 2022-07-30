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
        
        static func transform(_ localizedString: String) -> String? {
            switch localizedString {
            case Menu.all.rawValue.localized: return Menu.all.rawValue
            case Menu.personality.rawValue.localized: return Menu.personality.rawValue
            case Menu.gender.rawValue.localized: return Menu.gender.rawValue
            case Menu.type.rawValue.localized: return Menu.type.rawValue
            case Menu.species.rawValue.localized: return Menu.species.rawValue
            default: return nil
            }
        }
    }
    
    enum SearchScope: String {
        case all = "All"
        case liked = "Liked"
        case residents = "Residents"
        
        static func transform(_ localizedString: String) -> String? {
            switch localizedString {
            case SearchScope.all.rawValue.localized: return SearchScope.all.rawValue
            case SearchScope.liked.rawValue.localized: return SearchScope.liked.rawValue
            case SearchScope.residents.rawValue.localized: return SearchScope.residents.rawValue
            default: return nil
            }
        }
    }

    private let disposeBag = DisposeBag()
    private var currentSelected: [Menu: String] = [.all: Menu.all.rawValue]
    private var selectedKeyword = BehaviorRelay<[Menu: String]>(value: [.all: Menu.all.rawValue])
    
    private lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 105, height: 140)
        flowLayout.sectionInset = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        flowLayout.minimumLineSpacing = 20
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.registerNib(VillagersCell.self)
        return collectionView
    }()
    
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.showsScopeBar = true
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.placeholder = "Search a villager".localized
        searchController.searchBar.scopeButtonTitles = [
            SearchScope.all.rawValue.localized,
            SearchScope.liked.rawValue.localized,
            SearchScope.residents.rawValue.localized
        ]
        return searchController
    }()
    
    private lazy var activityIndicator: LoadingView = {
        let activityIndicator = LoadingView(backgroundColor: .acBackground, alpha: 1)
        view.addSubviews(activityIndicator)
        activityIndicator.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        activityIndicator.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        return activityIndicator
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        navigationController?.navigationBar.sizeToFit()
    }
    
    func bind(to reactor: VillagersReactor) {
        self.rx.viewDidLoad
            .map { VillagersReactor.Action.fetch }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)
        
        searchController.searchBar.rx.cancelButtonClicked
            .map { VillagersReactor.Action.searchText("") }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        searchController.searchBar.rx.text
            .compactMap { $0 }
            .map { VillagersReactor.Action.searchText($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        searchController.searchBar.rx.selectedScopeButtonIndex
            .compactMap { [weak self] in self?.searchController.searchBar.scopeButtonTitles?[$0] }
            .map { VillagersReactor.Action.selectedScope($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        selectedKeyword
            .map { VillagersReactor.Action.selectedMenu(keywords: $0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        collectionView.rx.itemSelected
            .map { VillagersReactor.Action.selectedVillager(indexPath: $0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.villagers }
            .bind(to: collectionView.rx.items(cellIdentifier: VillagersCell.className, cellType: VillagersCell.self)) { _, villager, cell in
                cell.setUp(villager)
            }.disposed(by: disposeBag)
        
        reactor.state.map { $0.isLoading }
            .bind(to: self.activityIndicator.rx.isAnimating)
            .disposed(by: disposeBag)
        
        searchController.searchBar.rx.selectedScopeButtonIndex
            .observe(on: MainScheduler.asyncInstance)
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.searchController.searchBar.endEditing(true)
                owner.selectedKeyword.accept(owner.currentSelected)
            }).disposed(by: disposeBag)
        
        selectedKeyword
            .map { !$0.keys.contains(.all) }
            .withUnretained(self)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { owner, isFiltering in
                owner.navigationItem.rightBarButtonItem?.image = UIImage(
                    systemName: isFiltering ? "arrow.up.arrow.down.circle.fill" : "arrow.up.arrow.down.circle"
                )
        }).disposed(by: disposeBag)
    }
    
    private func setUpViews() {
        view.backgroundColor = .acBackground
        setUpNavigationItem()
        setUpSearchController()
        view.addSubviews(collectionView)
        NSLayoutConstraint.activate([
            collectionView.heightAnchor.constraint(equalTo: view.heightAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
    
    private func setUpNavigationItem() {
        navigationItem.title = "Villagers".localized
        let moreButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.up.arrow.down.circle"),
            style: .plain,
            target: self,
            action: nil
        )
        moreButton.tintColor = .acNavigationBarTint
        navigationItem.rightBarButtonItem = moreButton
        navigationItem.rightBarButtonItem?.menu = createFilterMenu()
    }

    private func setUpSearchController() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func createFilterMenu() -> UIMenu {
        let menuItems: [(title: String, subTitle: [String])] = [
            (Menu.personality.rawValue.localized, Personality.allCases.map { $0.rawValue.localized }),
            (Menu.gender.rawValue.localized, Gender.allCases.map { $0.rawValue.localized }),
            (Menu.type.rawValue.localized, Subtype.allCases.map { $0.rawValue.localized }),
            (Menu.species.rawValue.localized, Specie.allCases.map { $0.rawValue.localized })
        ]
        
        let actionHandler: (UIAction) -> Void = { [weak self] action in
            for menuItem in menuItems where menuItem.subTitle.contains(action.title) {
                let menu = Menu(rawValue: Menu.transform(menuItem.title) ?? "") ?? .all
                self?.currentSelected[menu] = action.title
            }
            self?.currentSelected[Menu.all] = nil
            self?.navigationItem.rightBarButtonItem?.menu = self?.createFilterMenu()
        }
        let items: [UIMenu] = menuItems
            .map { UIMenu(title: $0.title, subTitles: $0.subTitle, actionHandler: actionHandler) }
        items.forEach { menu in
            menu.children.forEach { element in
                let action = element as? UIAction
                let menu = Menu(rawValue: Menu.transform(menu.title) ?? "") ?? .all
                if currentSelected[menu]?.contains(action?.title ?? "") == true {
                    action?.state = .on
                    action?.attributes = .disabled
                }
            }
        }
        
        let all = UIAction(title: Menu.all.rawValue.localized, handler: { [weak self] _ in
            self?.currentSelected = [Menu.all: Menu.all.rawValue]
            self?.navigationItem.rightBarButtonItem?.menu = self?.createFilterMenu()
        })
        if currentSelected[Menu.all] != nil {
            all.state = .on
            all.attributes = .disabled
        }
        selectedKeyword.accept(currentSelected)
        
        return UIMenu(title: "", options: .displayInline, children: [all] + items)
    }
}

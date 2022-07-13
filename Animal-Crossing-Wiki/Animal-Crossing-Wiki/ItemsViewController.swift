//
//  ItemsViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/05.
//

import UIKit
import RxSwift
import RxRelay

class ItemsViewController: UIViewController {
    enum Menu: Int {
        case all
        case month
        case collected
        case notCollected
        case name
        case sell
        
        var title: String {
            switch self {
            case .all: return "All".localized
            case .month: return "Month".localized
            case .name: return "Name".localized
            case .sell: return "Sell".localized
            case .collected: return "Collected".localized
            case .notCollected: return "Not collected".localized
            }
        }
        
        static let descending = "descending"
        static let ascending = "ascending"
        static let descendingIconName = "arrow.down"
        static let ascendingIconName = "arrow.up"
        
        static func transform(localized: String) -> Self {
            switch localized {
            case "All".localized: return .all
            case "Month".localized: return .month
            case "Name".localized: return .name
            case "Sell".localized: return .sell
            case "Collected".localized: return .collected
            case "Not collected".localized: return .notCollected
            default: return .all
            }
        }
    }

    var category: Category?
    private let disposeBag = DisposeBag()
    private var currentSelected: [Menu: String] = [.all: Menu.all.title]
    private var selectedKeyword = BehaviorRelay<[Menu: String]>(value: [.all: Menu.all.title])

    private lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 105, height: 175)
        flowLayout.sectionInset = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        flowLayout.minimumLineSpacing = 20
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.registerNib(CatalogCell.self)
        return collectionView
    }()
    
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.placeholder = "Search...".localized
        return searchController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
    }
    
    func bind(to viewModel: ItemsViewModel) {
        let input = ItemsViewModel.Input(
            searchBarText: searchController.searchBar.rx.text.asObservable(),
            didSelectedMenuKeyword: selectedKeyword.asObservable(),
            itemSelected: collectionView.rx.itemSelected.asObservable()
        )
        let output = viewModel.transform(input: input, disposeBag: disposeBag)
        
        output.items
            .bind(to: collectionView.rx.items(cellIdentifier: CatalogCell.className, cellType: CatalogCell.self)) { _, item, cell in
                cell.setUp(item)
            }.disposed(by: disposeBag)
        
        output.category
            .map { $0.rawValue.localized }
            .bind(to: navigationItem.rx.title)
            .disposed(by: disposeBag)
        
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
    
    func setUpFilterKeyword(_ keyword: [Menu: String]) {
        currentSelected = keyword
        if let category = category, Category.critters.contains(category) {
            navigationItem.title = "To catch now".localized
        } else {
            currentSelected[.month] = nil
            navigationItem.title = "Currently Available".localized
        }
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
        let filterButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.up.arrow.down.circle"),
            style: .plain,
            target: self,
            action: nil
        )
        filterButton.tintColor = .acNavigationBarTint
        self.navigationItem.rightBarButtonItem = filterButton
        filterButton.menu = createFilterAndSortMenu()
    }

    private func setUpSearchController() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func createFilterAndSortMenu() -> UIMenu {
        let menu = UIMenu(title: "", options: .displayInline, children: createFilteringMenuChildren())
        menu.children.forEach { action in
            let currentMenu = Menu.transform(localized: action.title)
            if self.currentSelected.keys.contains(currentMenu) {
                let action = action as? UIAction
                action?.state = .on
            }
        }
        return menu
    }
    
    private func createFilteringMenuChildren() -> [UIMenuElement] {
        let allAction = UIAction(title: Menu.all.title, handler: { [weak self] _ in
            self?.currentSelected = [Menu.all: Menu.all.title]
            self?.navigationItem.rightBarButtonItem?.menu = self?.createFilterAndSortMenu()
        })
        if currentSelected[.all] != nil {
            allAction.state = .on
            allAction.attributes = .disabled
        }
        let menuItems: [UIMenuElement] = [allAction] + [createSortMenu()] + createFilterMenu()
        selectedKeyword.accept(currentSelected)
        return menuItems
    }
    
    private func createSortMenu() -> UIMenu {
        let handler: (UIAction) -> Void = { [weak self] action in
            let rawValue = action.title == Menu.name.title ? 4 : 5
            let menu = Menu(rawValue: rawValue) ?? .name
            if self?.currentSelected[menu] == nil {
                self?.currentSelected[menu] = Menu.ascending
            } else if self?.currentSelected[menu] == Menu.ascending {
                self?.currentSelected[menu] = Menu.descending
            } else {
                self?.currentSelected[menu] = Menu.ascending
            }
            self?.currentSelected[.all] = nil
            if menu == .name {
                self?.currentSelected[.sell] = nil
            } else {
                self?.currentSelected[.name] = nil
            }
            self?.navigationItem.rightBarButtonItem?.menu = self?.createFilterAndSortMenu()
        }
        let name = UIAction(title: Menu.name.title, handler: handler)
        let sell = UIAction(title: Menu.sell.title, handler: handler)
        let menu = UIMenu(title: "", options: .displayInline, children: [name, sell])
        menu.children.forEach { action in
            let currentMenu = Menu.transform(localized: action.title)
            if currentSelected.keys.contains(currentMenu) {
                let action = action as? UIAction
                action?.state = .on
                action?.image = [Menu.name, Menu.sell].contains(currentMenu) ?
                currentSelected[currentMenu] == Menu.ascending ?
                UIImage(systemName: Menu.ascendingIconName) :
                UIImage(systemName: Menu.descendingIconName) :
                nil
            }
        }
        return menu
    }
    
    private func createFilterMenu() -> [UIMenuElement] {
        var filterMenuList = [UIMenuElement]()
        if let category = category, Category.critters.contains(category) {
            let actionHandler: (UIAction) -> Void = { [weak self] action in
                let menu = Menu.month
                self?.currentSelected[menu] = action.title
                self?.currentSelected[Menu.all] = nil
                self?.navigationItem.rightBarButtonItem?.menu = self?.createFilterAndSortMenu()
            }
            let monthActions = Array(1...12)
                .map { $0.description }
                .map { UIAction(title: $0, handler: actionHandler) }
            monthActions.forEach { action in
                let menu = Menu.month
                if currentSelected[menu] == action.title {
                    action.state = .on
                    action.attributes = .disabled
                }
            }
            let monthMenuTitle = currentSelected[.month] != nil ?
            (DateFormatter().monthSymbols[(Int(currentSelected[.month] ?? "1") ?? 1) - 1]) :
            Menu.month.title.localized
            let monthsMenu = UIMenu(title: monthMenuTitle, children: monthActions)
            filterMenuList.append(monthsMenu)
        }
        let notCollectedAction = UIAction(title: Menu.notCollected.title, handler: { [weak self] action in
            if self?.currentSelected[.collected] != nil {
                self?.currentSelected[.collected] = nil
            }
            self?.currentSelected[.notCollected] = self?.currentSelected[.notCollected] == nil ? action.title : nil
            self?.currentSelected[.all] = self?.currentSelected.isEmpty == true ? Menu.all.title : nil
            self?.navigationItem.rightBarButtonItem?.menu = self?.createFilterAndSortMenu()
        })
        
        let collectedAction = UIAction(title: Menu.collected.title, handler: { [weak self] action in
            if self?.currentSelected[.notCollected] != nil {
                self?.currentSelected[.notCollected] = nil
            }
            self?.currentSelected[.collected] = self?.currentSelected[.collected] == nil ? action.title : nil
            self?.currentSelected[.all] = self?.currentSelected.isEmpty == true ? Menu.all.title : nil
            self?.navigationItem.rightBarButtonItem?.menu = self?.createFilterAndSortMenu()
        })
        filterMenuList.append(contentsOf: [collectedAction, notCollectedAction])
        
        return filterMenuList
    }
}

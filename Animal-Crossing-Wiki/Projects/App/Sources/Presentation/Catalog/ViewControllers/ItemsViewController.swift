//
//  ItemsViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/05.
//

import UIKit
import RxSwift
import RxRelay

final class ItemsViewController: UIViewController {

    enum Mode: Equatable {
        case user
        case all
        case keyword(title: String, keyword: Keyword)
        case search
    }

    enum Menu: Int {
        case all
        case month
        case name
        case sell
        case catalog
        case allSelect
        case reset

        var title: String {
            switch self {
            case .all: return "All".localized
            case .month: return "Month".localized
            case .name: return "Name".localized
            case .sell: return "Sell".localized
            case .catalog: return "Catalog".localized
            case .allSelect: return "All Select".localized
            case .reset: return "Reset".localized
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
            case "Catalog".localized: return .catalog
            case "All Select".localized: return .allSelect
            case "Reset".localized: return .reset
            default: return .all
            }
        }
    }

    enum SearchScope: String, CaseIterable {
        case all = "All"
        case notCollected = "Not collected"
        case collected = "Collected"

        static func transform(_ localizedString: String) -> String? {
            switch localizedString {
            case SearchScope.all.rawValue.localized: return SearchScope.all.rawValue
            case SearchScope.collected.rawValue.localized: return SearchScope.collected.rawValue
            case SearchScope.notCollected.rawValue.localized: return SearchScope.notCollected.rawValue
            default: return nil
            }
        }
    }
    private var reactor: ItemsReactor!
    private var category: Category?
    private var mode: Mode = .all
    private var currentSelected: [Menu: String] = [.all: Menu.all.title]
    private var selectedKeyword = BehaviorRelay<[Menu: String]>(value: [:])
    private let disposeBag = DisposeBag()

    private lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 105, height: 175)
        flowLayout.sectionInset = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        flowLayout.minimumLineSpacing = 20
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.contentInset.bottom = 60
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.registerNib(CatalogCell.self)
        return collectionView
    }()

    private lazy var activityIndicator: LoadingView = {
        let activityIndicator = LoadingView(backgroundColor: .acBackground, alpha: 1)
        view.addSubviews(activityIndicator)
        activityIndicator.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        activityIndicator.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        return activityIndicator
    }()

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = "Search...".localized
        if mode != .user {
            searchController.searchBar.scopeButtonTitles = SearchScope.allCases.map { $0.rawValue.localized }
            searchController.searchBar.showsScopeBar = true
        }
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        return searchController
    }()

    private lazy var emptyView: EmptyView = EmptyView(
        title: "There are no villagers.".localized,
        description: "They appear here when you press the villager's heart button or home button.".localized
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if mode == .search {
            DispatchQueue.main.async { [weak self] in
                self?.searchController.searchBar.becomeFirstResponder()
            }
        }
    }

    func bind(to reactor: ItemsReactor, keyword: [Menu: String] = [:]) {
        self.reactor = reactor

        category = reactor.category
        switch reactor.mode {
        case .user: mode = .user
        case .keyword(let title, let keyword): mode = .keyword(title: title, keyword: keyword)
        case .all: mode = .all
        case .search: mode = .search
        }
        setUpFilterKeyword(keyword)

        self.rx.viewDidLoad
            .map { ItemsReactor.Action.fetch }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)

        searchController.searchBar.rx.cancelButtonClicked
            .map { ItemsReactor.Action.search(text: "") }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        searchController.searchBar.rx.text
            .compactMap { $0 }
            .debounce(.milliseconds(300), scheduler: MainScheduler.asyncInstance)
            .map { ItemsReactor.Action.search(text: $0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        selectedKeyword
            .map { ItemsReactor.Action.selectedMenu(keywords: $0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        searchController.searchBar.rx.selectedScopeButtonIndex
            .compactMap { [weak self] in self?.searchController.searchBar.scopeButtonTitles?[$0]}
            .map { ItemsReactor.Action.selectedScope($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        collectionView.rx.itemSelected
            .map { ItemsReactor.Action.selectedItem(indexPath: $0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        reactor.state.map { $0.isLoading }
            .observe(on: MainScheduler.asyncInstance)
            .bind(to: activityIndicator.rx.isAnimating)
            .disposed(by: disposeBag)

        reactor.state.map { $0.items }
            .bind(to: collectionView.rx.items(cellIdentifier: CatalogCell.className, cellType: CatalogCell.self)) { _, item, cell in
                cell.setUp(item)
            }.disposed(by: disposeBag)

        reactor.state.map { $0.items }
            .map { !$0.isEmpty }
            .bind(to: emptyView.rx.isHidden)
            .disposed(by: disposeBag)

        if [Mode.all, Mode.user].contains(mode), navigationItem.title == nil {
            reactor.state.map { $0.category }
                .map { $0.rawValue.localized }
                .bind(to: navigationItem.rx.title)
                .disposed(by: disposeBag)
        }

        selectedKeyword
            .filter { $0.isEmpty == false }
            .map { !$0.keys.contains(.all) }
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onNext: { owner, isFiltering in
                owner.navigationItem.rightBarButtonItem?.image = UIImage(
                    systemName: isFiltering ? "arrow.up.arrow.down.circle.fill" : "ellipsis.circle"
                )
            }).disposed(by: disposeBag)

        searchController.searchBar.rx.text
            .map { $0 != "" }
            .subscribe(with: self, onNext: { owner, isSearching in
                if isSearching {
                    owner.emptyView.editLabel(
                        title: "Item is empty.".localized,
                        description: "There are no results for your search.".localized
                    )
                }
            }).disposed(by: disposeBag)

        searchController.searchBar.rx.selectedScopeButtonIndex
            .compactMap { SearchScope.allCases[safe: $0] }
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(with: self, onNext: { owner, currentScope in
                switch currentScope {
                case .all:
                    owner.emptyView.editLabel(
                        title: "Item is empty.".localized,
                        description: "Please check the network status.".localized
                    )
                case .notCollected:
                    owner.emptyView.editLabel(
                        title: "Item is empty.".localized,
                        description: "There are no more items to collect.".localized
                    )
                case .collected:
                    owner.emptyView.editLabel(
                        title: "There are no collectibles.".localized,
                        description: "when you check some items, they'll be displayed here.".localized
                    )
                }
                owner.searchController.searchBar.endEditing(true)
                owner.selectedKeyword.accept(owner.currentSelected)
            }).disposed(by: disposeBag)
    }

    private func setUpFilterKeyword(_ keyword: [Menu: String]) {
        guard keyword.isEmpty == false else {
            return
        }
        currentSelected = keyword
        if let category = category, Category.critters.contains(category) {
            navigationItem.title = "To catch now".localized
        } else {
            currentSelected[.month] = nil
            navigationItem.title = "Currently Available".localized
        }
        searchController.searchBar.rx.selectedScopeButtonIndex.onNext(1)
    }

    private func setUpViews() {
        view.backgroundColor = .acBackground
        view.addSubviews(collectionView, activityIndicator, emptyView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            activityIndicator.widthAnchor.constraint(equalTo: view.widthAnchor),
            activityIndicator.heightAnchor.constraint(equalTo: view.heightAnchor),
            emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -40)
        ])
        setUpNavigationItem()
    }

    private func setUpNavigationItem() {
        switch mode {
        case .keyword(let title, _): navigationItem.title = title.lowercased().localized.capitalized
            
        case .search:
            navigationItem.title = "searching".lowercased().localized.capitalized
        default: break
        }
        let moreButton = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis.circle"),
            style: .plain,
            target: self,
            action: nil
        )
        moreButton.tintColor = .acNavigationBarTint
        navigationItem.rightBarButtonItem = moreButton
        moreButton.menu = createMoreMenu()
    }

}

// MARK: - Menus
extension ItemsViewController {

    private func createMoreMenu() -> UIMenu {
        let menu = UIMenu(title: "", options: .displayInline, children: createMoreMenuChildren())
        menu.children.forEach { action in
            let currentMenu = Menu.transform(localized: action.title)
            if currentSelected.keys.contains(currentMenu) {
                let action = action as? UIAction
                action?.state = .on
                action?.attributes = .disabled
            }
        }
        return menu
    }

    private func createMoreMenuChildren() -> [UIMenuElement] {
        let allAction = UIAction(title: Menu.all.title, handler: { [weak self] _ in
            self?.currentSelected = [Menu.all: Menu.all.title]
            self?.navigationItem.rightBarButtonItem?.menu = self?.createMoreMenu()
        })
        if currentSelected[.all] != nil {
            allAction.state = .on
            allAction.attributes = .disabled
        }
        let menuItems: [UIMenuElement] = [allAction] + [createSortMenu()] + createFilterMenu() + [createCheckMenu()]
        selectedKeyword.accept(currentSelected)
        return menuItems
    }

    private func createSortMenu() -> UIMenu {
        let handler: (UIAction) -> Void = { [weak self] action in
            let rawValue = action.title == Menu.name.title ? 2 : 3
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
            self?.navigationItem.rightBarButtonItem?.menu = self?.createMoreMenu()
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
        guard mode != .user else {
            return []
        }
        var filterMenuList = [UIMenuElement]()
        if let category = category, Category.critters.contains(category) {
            let actionHandler: (UIAction) -> Void = { [weak self] action in
                let menu = Menu.month
                self?.currentSelected[menu] = action.title
                self?.currentSelected[Menu.all] = nil
                self?.navigationItem.rightBarButtonItem?.menu = self?.createMoreMenu()
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
            (Calendar.current.monthSymbols[(Int(currentSelected[.month] ?? "1") ?? 1) - 1]) :
            Menu.month.title.localized
            let monthsMenu = UIMenu(title: monthMenuTitle, children: monthActions)
            filterMenuList.append(monthsMenu)
        }

        // Catalog Filter Menu - catalog 속성이 있는 카테고리에만 표시
        if let category = category, Category.catalogFilterable.contains(category) {
            filterMenuList.append(createCatalogFilterMenu())
        }

        return filterMenuList
    }

    private func createCatalogFilterMenu() -> UIMenu {
        let actionHandler: (UIAction) -> Void = { [weak self] action in
            let menu = Menu.catalog
            self?.currentSelected[menu] = action.title
            self?.currentSelected[Menu.all] = nil
            self?.navigationItem.rightBarButtonItem?.menu = self?.createMoreMenu()
        }

        let catalogActions = Catalog.allCases.map { catalog in
            UIAction(title: catalog.localizedName, handler: actionHandler)
        }
        catalogActions.forEach { action in
            let menu = Menu.catalog
            if currentSelected[menu] == action.title {
                action.state = .on
                action.attributes = .disabled
            }
        }

        let catalogMenuTitle = currentSelected[.catalog] ?? Menu.catalog.title.localized
        return UIMenu(title: catalogMenuTitle, children: catalogActions)
    }

    private func createCheckMenu() -> UIMenu {
        let allSelectAction = UIAction(
            title: Menu.allSelect.title,
            image: UIImage(systemName: "text.badge.checkmark")
        ) { [weak self] _ in
            guard let owner = self else {
                return
            }
            owner.showAlert(title: "Notice".localized, message: "Are you sure you want to check them all?".localized)
                .filter { $0 == true }
                .subscribe(onNext: { [weak owner] _ in
                    guard let owner else {
                        return
                    }
                    owner.reactor.action.onNext(.selectedMenu(keywords: [.allSelect: ""]))
                    owner.selectedKeyword.accept(owner.selectedKeyword.value)
                }).disposed(by: owner.disposeBag)
            owner.navigationItem.rightBarButtonItem?.menu = owner.createMoreMenu()
        }
        let resetAction = UIAction(
            title: Menu.reset.title,
            image: UIImage(systemName: "arrow.counterclockwise")
        ) { [weak self] _ in
            guard let owner = self else {
                return
            }
            owner.showAlert(title: "Notice".localized, message: "Are you sure you want to uncheck them all?".localized)
                .filter { $0 == true }
                .subscribe(with: owner, onNext: { owner, _ in
                    owner.reactor.action.onNext(.selectedMenu(keywords: [.reset: ""]))
                    owner.selectedKeyword.accept(owner.selectedKeyword.value)
                }).disposed(by: owner.disposeBag)
            owner.navigationItem.rightBarButtonItem?.menu = owner.createMoreMenu()
        }
        return UIMenu(title: "", options: .displayInline, children: [allSelectAction, resetAction])
    }

}

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
        case name
        case sell
        case uncollected
        
        var title: String {
            switch self {
            case .all: return "All"
            case .month: return "Month"
            case .name: return "Name"
            case .sell: return "Sell"
            case .uncollected: return "Uncollected"
            }
        }
        
        static let descending = "descending"
        static let ascending = "ascending"
        
        static func menu(title: String) -> Self {
            switch title {
            case "All": return .all
            case "Month": return .month
            case "Name": return .name
            case "Sell": return .sell
            case "Uncollected": return .uncollected
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
        flowLayout.itemSize = CGSize(width: 100, height: 175)
        flowLayout.sectionInset = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        flowLayout.minimumLineSpacing = 25
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.registerNib(CatalogCell.self)
        return collectionView
    }()
    
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.placeholder = "Search..."
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
            .map { $0.rawValue }
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
        filterButton.menu = createFilterMenu()
    }

    private func setUpSearchController() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func createFilterMenu() -> UIMenu {
        let menu = UIMenu(title: "", options: .displayInline, children: createFilteringMenuChildren())
        menu.children.forEach { action in
            let currentMenu = Menu.menu(title: action.title)
            if self.currentSelected.keys.contains(currentMenu) {
                let action = action as? UIAction
                action?.state = .on
            }
            if self.currentSelected[.all] != nil {
                let all = menu.children.first as? UIAction
                all?.state = .on
                all?.attributes = .disabled
            }
        }
        
        return menu
    }
    
    private func createFilteringMenuChildren() -> [UIMenuElement] {
        let allAction = UIAction(title: Menu.all.title, handler: { [weak self] _ in
            self?.currentSelected = [Menu.all: Menu.all.title]
            self?.navigationItem.rightBarButtonItem?.menu = self?.createFilterMenu()
        })
        let uncollectionAction = UIAction(title: Menu.uncollected.title, handler: { [weak self] action in
            self?.currentSelected[.uncollected] = self?.currentSelected[.uncollected] == nil ? action.title : nil
            self?.currentSelected[.all] = self?.currentSelected.isEmpty == true ? Menu.all.title : nil
            self?.navigationItem.rightBarButtonItem?.menu = self?.createFilterMenu()
        })
        
        var menuItems = [UIMenuElement]()
        if let category = category, Category.critters.contains(category) {
            menuItems.append(contentsOf: [allAction] + [createMonthMenu()] + createSortActions() + [uncollectionAction])
        } else {
            menuItems.append(contentsOf: [allAction] + createSortActions() + [uncollectionAction])
        }
        selectedKeyword.accept(currentSelected)
        return menuItems
    }
    
    private func createSortActions() -> [UIAction] {
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
            self?.navigationItem.rightBarButtonItem?.menu = self?.createFilterMenu()
        }
        let name = UIAction(title: Menu.name.title, handler: handler)
        let sell = UIAction(title: Menu.sell.title, handler: handler)
        
        return [name, sell]
    }
    
    private func createMonthMenu() -> UIMenu {
        let actionHandler: (UIAction) -> Void = { [weak self] action in
            let menu = Menu.month
            self?.currentSelected[menu] = action.title
            self?.currentSelected[Menu.all] = nil
            self?.navigationItem.rightBarButtonItem?.menu = self?.createFilterMenu()
        }
        let monthMenu = UIMenu(
            title: Menu.month.title,
            subTitles: Array(1...12).map { $0.description },
            actionHandler: actionHandler
        )
        monthMenu.children.forEach { action in
            let menu = Menu.month
            if currentSelected[menu] == action.title {
                let action = action as? UIAction
                action?.state = .on
                action?.attributes = .disabled
            }
        }
        
        return monthMenu
    }
}

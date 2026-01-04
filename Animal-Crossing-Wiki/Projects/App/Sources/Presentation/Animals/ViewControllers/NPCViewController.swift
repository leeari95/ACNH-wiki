//
//  NPCViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/29.
//

import UIKit
import RxSwift
import RxRelay

final class NPCViewController: UIViewController {
    enum Menu: String {
        case all = "All"
        case gender = "Gender"

        static func transform(_ localizedString: String) -> String? {
            switch localizedString {
            case Menu.all.rawValue.localized: return Menu.all.rawValue
            case Menu.gender.rawValue.localized: return Menu.gender.rawValue
            default: return nil
            }
        }
    }

    enum SearchScope: String, CaseIterable {
        case all = "All"
        case liked = "Liked"

        static func transform(_ localizedString: String) -> String? {
            switch localizedString {
            case SearchScope.all.rawValue.localized: return SearchScope.all.rawValue
            case SearchScope.liked.rawValue.localized: return SearchScope.liked.rawValue
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
        collectionView.contentInset.bottom = 60
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.registerNib(VillagersCell.self)
        return collectionView
    }()

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.showsScopeBar = true
        searchController.searchBar.placeholder = "Search a npc".localized
        searchController.searchBar.scopeButtonTitles = SearchScope.allCases.map { $0.rawValue.localized }
        return searchController
    }()

    private lazy var activityIndicator: LoadingView = {
        let activityIndicator = LoadingView(backgroundColor: .acBackground, alpha: 1)
        view.addSubviews(activityIndicator)
        activityIndicator.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        activityIndicator.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        return activityIndicator
    }()

    private lazy var emptyView: EmptyView = EmptyView(
        title: "There are no villagers.".localized,
        description: "They appear here when you press the npc's heart button or home button.".localized
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
    }

    func bind(to reactor: NPCReactor) {
        self.rx.viewDidLoad
            .map { NPCReactor.Action.fetch }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)

        searchController.searchBar.rx.cancelButtonClicked
            .map { NPCReactor.Action.searchText("") }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        searchController.searchBar.rx.text
            .compactMap { $0 }
            .map { NPCReactor.Action.searchText($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        searchController.searchBar.rx.text
            .map { $0 != "" }
            .subscribe(onNext: { [weak self] isSearching in
                if isSearching {
                    self?.emptyView.editLabel(
                        title: "There are no npc.".localized,
                        description: "There are no results for your search.".localized
                    )
                }
            }).disposed(by: disposeBag)

        searchController.searchBar.rx.selectedScopeButtonIndex
            .compactMap { [weak self] in self?.searchController.searchBar.scopeButtonTitles?[$0] }
            .map { NPCReactor.Action.selectedScope($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        selectedKeyword
            .map { NPCReactor.Action.selectedMenu(keywords: $0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        collectionView.rx.itemSelected
            .map { NPCReactor.Action.selectedNPC(indexPath: $0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        reactor.state.map { $0.npcs }
            .bind(to: collectionView.rx.items(cellIdentifier: VillagersCell.className, cellType: VillagersCell.self)) { _, npc, cell in
                cell.setUp(npc)
            }.disposed(by: disposeBag)

        reactor.state.map { $0.npcs }
            .map { !$0.isEmpty }
            .bind(to: emptyView.rx.isHidden)
            .disposed(by: disposeBag)

        reactor.state.map { $0.isLoading }
            .bind(to: self.activityIndicator.rx.isAnimating)
            .disposed(by: disposeBag)

        searchController.searchBar.rx.selectedScopeButtonIndex
            .observe(on: MainScheduler.asyncInstance)
            .compactMap { SearchScope.allCases[safe: $0] }
            .subscribe(with: self, onNext: { owner, currentScope in
                switch currentScope {
                case .all:
                    owner.emptyView.editLabel(
                        title: "There are no npc.".localized,
                        description: "Please check the network status.".localized
                    )
                case .liked:
                    owner.emptyView.editLabel(
                        title: "There are no npc.".localized,
                        description: "Tap the npc's heart button and it will appear here.".localized
                    )
                }
                owner.searchController.searchBar.endEditing(true)
                owner.selectedKeyword.accept(owner.currentSelected)
            }).disposed(by: disposeBag)

        selectedKeyword
            .map { !$0.keys.contains(.all) }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self]  isFiltering in
                self?.navigationItem.rightBarButtonItem?.image = UIImage(
                    systemName: isFiltering ? "arrow.up.arrow.down.circle.fill" : "arrow.up.arrow.down.circle"
                )
        }).disposed(by: disposeBag)
    }

    private func setUpViews() {
        view.backgroundColor = .acBackground
        setUpNavigationItem()
        setUpSearchController()
        view.addSubviews(collectionView, emptyView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -40)
        ])
    }

    private func setUpNavigationItem() {
        navigationItem.title = "NPC"
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
            (Menu.gender.rawValue.localized, Gender.allCases.map { $0.rawValue.lowercased().localized })
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

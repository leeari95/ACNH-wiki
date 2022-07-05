//
//  CatalogViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/04.
//

import UIKit
import RxSwift

class CatalogViewController: UIViewController {
    
    var viewModel: CatalogViewModel?
    private let disposeBag = DisposeBag()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = .clear
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        bind()
    }
    
    private func setUpNavigationItem() {
        view.backgroundColor = .acBackground
        navigationItem.title = "Catalog"
    }
    
    private func setUpViews() {
        setUpNavigationItem()
        view.addSubviews(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
    
    private func bind() {
        let input = CatalogViewModel.Input(
            selectedCategory: tableView.rx.modelSelected((title: Category, count: Int).self).asObservable()
        )
        
        let output = viewModel?.transform(input: input, disposeBag: disposeBag)
        
        output?.catagories
            .bind(to: tableView.rx.items) { _, _, item in
                let cell = UITableViewCell()
                var content = cell.defaultContentConfiguration()
                content.text = item.title.rawValue
                content.textProperties.color = .acText
                content.textProperties.font = .preferredFont(for: .callout, weight: .bold)
                content.secondaryText = item.count.description
                content.image = UIImage(named: item.title.iconName)
                content.imageProperties.maximumSize = CGSize(width: 35, height: 35)
                cell.contentConfiguration = content
                cell.accessoryType = .disclosureIndicator
                cell.selectedBackgroundView = UIView()
                cell.selectedBackgroundView?.backgroundColor = .acText.withAlphaComponent(0.3)
                cell.backgroundColor = .acSecondaryBackground
                return cell
            }.disposed(by: disposeBag)
        
        tableView.rx.itemSelected
            .subscribe(onNext: { indexPath in
                self.tableView.deselectRow(at: indexPath, animated: true)
            }).disposed(by: disposeBag)
    }
}

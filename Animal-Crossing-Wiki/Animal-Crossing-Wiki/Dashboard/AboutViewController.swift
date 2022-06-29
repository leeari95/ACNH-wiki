//
//  AboutViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/28.
//

import UIKit
import RxSwift
import RxDataSources

class AboutViewController: UIViewController {

    private let disposeBag = DisposeBag()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .clear
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        bind()
    }
    
    private func setUpViews() {
        view.backgroundColor = .acBackground
        self.navigationItem.title = "About"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark.app.fill"),
            style: .plain,
            target: self,
            action: #selector(didTapCancelButton(_:))
        )
        
        view.addSubviews(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
    
    private func bind() {
        let items = Observable.just([
            SectionModel(model: "The app", items: AboutItem.theApp),
            SectionModel(model: "Credit / Thanks", items: AboutItem.acknowledgement)
        ])

        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, (AboutItem)>> { _, _, _, item in
            let cell = UITableViewCell()
            var content = cell.defaultContentConfiguration()
            content.image = UIImage(systemName: item.icon)
            content.imageProperties.maximumSize = CGSize(width: 25, height: 25)
            content.imageProperties.tintColor = .acHeaderBackground
            content.text = item.title
            content.textProperties.color = .acText
            content.textProperties.font = .preferredFont(forTextStyle: .callout)
            cell.contentConfiguration = content
            
            cell.backgroundColor = .acSecondaryBackground
            cell.accessoryType = .disclosureIndicator
            cell.selectedBackgroundView = UIView()
            cell.selectedBackgroundView?.backgroundColor = .acText.withAlphaComponent(0.3)
            
            return cell
        } titleForHeaderInSection: { dataSource, sectionIndex in
            return dataSource[sectionIndex].model
        }
        
        items.bind(
            to: tableView.rx.items(dataSource: dataSource)
        ).disposed(by: disposeBag)
        
        tableView.rx.itemSelected
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { indexPath in
                self.tableView.deselectRow(at: indexPath, animated: true)
            }).disposed(by: disposeBag)
        
        tableView.rx.modelSelected(AboutItem.self)
            .compactMap { $0.url }
            .subscribe(onNext: { url in
                UIApplication.shared.open(url)
            }).disposed(by: disposeBag)
    }
    
    @objc private func didTapCancelButton(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

}

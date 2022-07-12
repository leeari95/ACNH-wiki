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
    
    private lazy var cancelButton: UIBarButtonItem = {
        return .init(
            image: UIImage(systemName: "xmark.app.fill"),
            style: .plain,
            target: self,
            action: nil
        )
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
    }
    
    private func setUpViews() {
        view.backgroundColor = .acBackground
        self.navigationItem.title = "About".localized
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = cancelButton
        
        view.addSubviews(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
    
    func bind(to viewModel: AboutViewModel) {
        let input = AboutViewModel.Input(
            didTapCancel: cancelButton.rx.tap.asObservable()
        )
        let output = viewModel.transform(input: input, disposeBag: disposeBag)

        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, AboutItem>> { _, _, _, item in
            let cell = UITableViewCell()
            var content = cell.defaultContentConfiguration()
            content.image = UIImage(systemName: item.icon)
            content.imageProperties.maximumSize = CGSize(width: 25, height: 25)
            content.imageProperties.tintColor = item.icon.contains("heart") ? .systemRed : .acHeaderBackground
            content.text = item.title.localized
            content.textProperties.color = .acText
            content.textProperties.font = .preferredFont(forTextStyle: .callout)
            if let description = item.description {
                content.secondaryText = description
                content.secondaryTextProperties.color = .acText
            }
            cell.contentConfiguration = content
            cell.backgroundColor = .acSecondaryBackground
            cell.selectedBackgroundView = UIView()
            cell.selectedBackgroundView?.backgroundColor = item.url == nil ? .clear : .acText.withAlphaComponent(0.3)
            cell.accessoryType = item.url == nil ? .none : .disclosureIndicator
            return cell
        } titleForHeaderInSection: { dataSource, sectionIndex in
            return dataSource[sectionIndex].model
        }
        
        output.items
            .map { $0.map { SectionModel(model: $0.title, items: $0.items) } }
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        tableView.rx.itemSelected
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .subscribe(onNext: { owner, indexPath in
                owner.tableView.deselectRow(at: indexPath, animated: true)
            }).disposed(by: disposeBag)
        
        tableView.rx.modelSelected(AboutItem.self)
            .compactMap { $0.url }
            .subscribe(onNext: { url in
                UIApplication.shared.open(url)
            }).disposed(by: disposeBag)
    }
}

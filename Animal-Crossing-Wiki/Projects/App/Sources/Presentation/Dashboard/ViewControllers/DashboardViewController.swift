//
//  DashboardViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/05/04.
//

import UIKit
import RxSwift
import SwiftUI

final class DashboardViewController: UIViewController {

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEE, MMM d")
        return formatter.string(from: Date())
    }

    private let disposeBag = DisposeBag()
    private lazy var sectionsScrollView = SectionsScrollView()

    private lazy var moreButton: UIBarButtonItem = {
        return .init(
            image: UIImage(systemName: "ellipsis.circle"),
            style: .plain,
            target: self,
            action: nil
        )
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDate()
    }

    private func setUpViews() {
        view.backgroundColor = .acBackground
        navigationItem.rightBarButtonItem = moreButton

        view.addSubviews(sectionsScrollView)

        NSLayoutConstraint.activate([
            sectionsScrollView.topAnchor.constraint(equalTo: view.topAnchor),
            sectionsScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sectionsScrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            sectionsScrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }

    private func updateDate() {
        navigationItem.title = dateString
    }

    func setUpViewModels(
        userInfoVM: UserInfoReactor,
        tasksVM: TodaysTasksSectionReactor,
        villagersVM: VillagersSectionReactor,
        progressVM: CollectionProgressSectionReactor,
        statisticsVM: CollectionStatisticsSectionReactor,
        fixeVisitdNPCListVM: NpcsSectionReactor,
        randomVisitNPCListVM: NpcsSectionReactor
    ) {
        let userInfoSection = SectionView(
            title: "My Island".localized,
            iconName: "leaf.fill",
            contentView: UserInfoView(userInfoVM)
        )
        let tasksSection = SectionView(
            title: "Today's Tasks".localized,
            iconName: "checkmark.seal.fill",
            contentView: TodaysTasksView(tasksVM)
        )
        let villagersSection = SectionView(
            title: "My Villagers".localized,
            iconName: "person.circle.fill",
            contentView: VillagersView(villagersVM)
        )
        let progressSection = SectionView(
            title: "Collection Progress".localized,
            iconName: "chart.pie.fill",
            contentView: CollectionProgressView(viewModel: progressVM)
        )
        let statisticsSection = SectionView(
            title: "Collection Statistics".localized,
            iconName: "chart.bar.fill",
            contentView: CollectionStatisticsView(viewModel: statisticsVM)
        )
        let randomVisitResidentsSectionView = SectionView(
            title: "Residents who can visit randomly on weekdays".localized,
            iconName: "bubbles.and.sparkles.fill",
            contentView: NpcsView(randomVisitNPCListVM)
        )
        let fixedVisitResidentsSectionView = SectionView(
            title: "Residents who visit regularly".localized,
            iconName: "pin.fill",
            contentView: NpcsView(fixeVisitdNPCListVM)
        )
        sectionsScrollView.addSection(userInfoSection,
                                      tasksSection,
                                      villagersSection,
                                      progressSection,
                                      statisticsSection,
                                      randomVisitResidentsSectionView,
                                      fixedVisitResidentsSectionView)
    }

    func bind(to reactor: DashboardReactor) {
        moreButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let owner = self else {
                    return
                }
                owner.showSelectedItemAlert(
                    [DashboardReactor.Menu.about.rawValue.localized, DashboardReactor.Menu.setting.rawValue.localized],
                    currentItem: nil
                ).map { DashboardReactor.Action.selected(title: $0) }
                    .bind(to: reactor.action )
                    .disposed(by: owner.disposeBag)
            }).disposed(by: disposeBag)
    }
}

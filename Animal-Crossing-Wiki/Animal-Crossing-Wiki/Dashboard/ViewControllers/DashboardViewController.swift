//
//  DashboardViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/05/04.
//

import UIKit
import RxSwift

class DashboardViewController: UIViewController {

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
    
    private func setUpViews() {
        view.backgroundColor = .acBackground
        navigationItem.title = dateString
        navigationItem.rightBarButtonItem = moreButton
        
        view.addSubviews(sectionsScrollView)
        
        NSLayoutConstraint.activate([
            sectionsScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            sectionsScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            sectionsScrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            sectionsScrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
    
    func setUpViewModels(
        userInfoVM: UserInfoSectionViewModel,
        tasksVM: TodaysTasksSectionViewModel,
        villagersVM: VillagersSectionViewModel,
        progressVM: CollectionProgressSectionViewModel,
        musicPlayerVM: MusicPlayerViewModel
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
        let musicPlayerSection = SectionView(
            title: "Music Player".localized,
            iconName: "music.quarternote.3",
            contentView: MusicPlayerView(viewModel: musicPlayerVM)
        )
        sectionsScrollView.addSection(
            userInfoSection, tasksSection, villagersSection, progressSection, musicPlayerSection
        )
    }

    func bind(to viewModel: DashboardViewModel) {
        let input = DashboardViewModel.Input(
            didTapMore: moreButton.rx.tap.asObservable()
        )
        viewModel.bind(input: input, disposeBag: disposeBag)
    }
}

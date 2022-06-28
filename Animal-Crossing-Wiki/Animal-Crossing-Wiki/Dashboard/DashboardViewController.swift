//
//  DashboardViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/05/04.
//

import UIKit

class DashboardViewController: UIViewController {
    
    var coordinator: DashboardCoordinator?
    
    private lazy var tasksSection = TodaysTasksSesction(TodaysTasksSesctionViewModel(coordinator: coordinator))
    private lazy var sectionsScrollView = SectionsScrollView(
        SectionView(title: "My Island", iconName: "sun.haze", contentView: UserInfoSection(UserInfoSectionViewModel())),
        SectionView(title: "Today's Tasks", iconName: "checkmark.seal.fill", contentView: tasksSection),
        SectionView(
            title: "My Villagers",
            iconName: "person.circle.fill",
            contentView: VillagersSection(VillagersSectionViewModel())
        ),
        SectionView(title: "Collection Progress", iconName: "chart.pie.fill", contentView: CollecitonProgressSection())
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
    }
    
    private func setUpViews() {
        view.backgroundColor = .acBackground
        navigationItem.title = Date().formatted("M월 d일, EEEE")
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "slider.horizontal.3"),
            style: .plain,
            target: self,
            action: #selector(didTapSettingButton(_:))
        )
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "info.circle"),
            style: .plain,
            target: self,
            action: #selector(didTapAboutButton(_:))
        )
        
        view.addSubviews(sectionsScrollView)
        
        NSLayoutConstraint.activate([
            sectionsScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            sectionsScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            sectionsScrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            sectionsScrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])

    }
    
    @objc private func didTapSettingButton(_ sender: UIBarButtonItem) {
        coordinator?.presentToSetting()
    }

    @objc private func didTapAboutButton(_ sender: UIBarButtonItem) {
        coordinator?.presentToAbout()
    }
}

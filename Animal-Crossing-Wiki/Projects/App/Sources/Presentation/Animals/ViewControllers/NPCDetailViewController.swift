//
//  NPCDetailViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/04.
//

import UIKit
import RxSwift

class NPCDetailViewController: UIViewController {

    private let disposeBag = DisposeBag()

    private lazy var sectionsScrollView: SectionsScrollView = SectionsScrollView()

    private lazy var likeButton: UIButton = {
        let button = UIButton()
        button.tintColor = .red
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
    }

    private func setUpViews() {
        if navigationController?.viewControllers.count == 1 {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "xmark.circle.fill"),
                style: .plain,
                target: self,
                action: nil
            )
            navigationItem.leftBarButtonItem?.rx.tap
                .subscribe(with: self, onNext: { owner, _ in
                    owner.dismiss(animated: true)
                }).disposed(by: disposeBag)
        }
        setUpNavigationItem()
        view.backgroundColor = .acBackground
        view.addSubviews(sectionsScrollView)

        NSLayoutConstraint.activate([
            sectionsScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            sectionsScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sectionsScrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            sectionsScrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }

    private func setUpNavigationItem() {
        let likeBarButton = UIBarButtonItem(customView: likeButton)
        navigationItem.rightBarButtonItems = [likeBarButton]
    }

    func bind(to reactor: NPCDetailReactor) {
        let buttonConfigure = UIImage.SymbolConfiguration(textStyle: .callout, scale: .large)
        self.rx.viewDidLoad
            .map { NPCDetailReactor.Action.fetch }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)

        likeButton.rx.tap
            .map { NPCDetailReactor.Action.like }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)

        reactor.state.map { $0.isLiked }
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self]  isLiked in
                self?.likeButton.setImage(
                    UIImage(systemName: isLiked ? "heart.fill" : "heart")?.withConfiguration(buttonConfigure),
                    for: .normal
                )
            }).disposed(by: disposeBag)

        reactor.state.map { $0.npc }
            .take(1)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self]  npc in
                let detailSection = NPCDetailView(npc)
                self?.sectionsScrollView.addSection(SectionView(contentView: detailSection))
                self?.navigationItem.title = npc.translations.localizedName()
            }).disposed(by: disposeBag)
    }
}

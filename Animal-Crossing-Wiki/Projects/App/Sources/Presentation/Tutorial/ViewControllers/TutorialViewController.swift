//
//  TutorialViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Claude on 2026/01/01.
//

import UIKit
import RxSwift
import RxCocoa

final class TutorialViewController: UIViewController {

    // MARK: - Types

    struct PageContent {
        let imageName: String
        let title: String
        let description: String
    }

    // MARK: - Constants

    static let pageContents: [PageContent] = [
        PageContent(imageName: "leaf.fill", title: "Tutorial.welcome.title".localized, description: "Tutorial.welcome.description".localized),
        PageContent(imageName: "book.fill", title: "Tutorial.catalog.title".localized, description: "Tutorial.catalog.description".localized),
        PageContent(imageName: "heart.fill", title: "Tutorial.collection.title".localized, description: "Tutorial.collection.description".localized),
        PageContent(imageName: "checkmark.seal.fill", title: "Tutorial.tasks.title".localized, description: "Tutorial.tasks.description".localized),
        PageContent(imageName: "gearshape.fill", title: "Tutorial.settings.title".localized, description: "Tutorial.settings.description".localized)
    ]

    // MARK: - Properties

    private let disposeBag = DisposeBag()
    private let reactor: TutorialReactor

    private var pages: [TutorialPageViewController] = []

    // MARK: - UI Components

    private lazy var pageViewController: UIPageViewController = {
        let pageVC = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
        pageVC.dataSource = self
        pageVC.delegate = self
        return pageVC
    }()

    private lazy var pageControl: UIPageControl = {
        let control = UIPageControl()
        control.currentPageIndicatorTintColor = .acHeaderBackground
        control.pageIndicatorTintColor = .systemGray4
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    private lazy var skipButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Tutorial.skip".localized, for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Tutorial.next".localized, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.backgroundColor = .acHeaderBackground
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Initialization

    init(reactor: TutorialReactor) {
        self.reactor = reactor
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        setUpPages()
        bind()
    }

    // MARK: - Setup

    private func setUpViews() {
        view.backgroundColor = .acBackground

        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(pageControl)
        view.addSubview(skipButton)
        view.addSubview(nextButton)

        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -20),

            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -20),

            skipButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            skipButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),

            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            nextButton.widthAnchor.constraint(equalToConstant: 120),
            nextButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    private func setUpPages() {
        pages = Self.pageContents.enumerated().map { index, content in
            TutorialPageViewController(
                imageName: content.imageName,
                titleText: content.title,
                descriptionText: content.description,
                pageIndex: index
            )
        }

        pageControl.numberOfPages = pages.count
        pageControl.currentPage = 0

        if let firstPage = pages.first {
            pageViewController.setViewControllers([firstPage], direction: .forward, animated: false)
        }
    }

    // MARK: - Binding

    private func bind() {
        // Skip button action
        skipButton.rx.tap
            .map { TutorialReactor.Action.skip }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // Next button action
        nextButton.rx.tap
            .map { TutorialReactor.Action.nextPage }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // State binding - currentPage (이전 페이지와 현재 페이지를 함께 추적하여 방향 결정)
        reactor.state
            .map { $0.currentPage }
            .distinctUntilChanged()
            .scan((previous: 0, current: 0)) { accumulated, newValue in
                (previous: accumulated.current, current: newValue)
            }
            .skip(1) // 초기 상태 스킵 (setUpPages에서 이미 첫 페이지 설정됨)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] pageChange in
                guard let self = self else { return }
                self.navigateToPage(from: pageChange.previous, to: pageChange.current)
                self.pageControl.currentPage = pageChange.current
                self.updateButtonTitle(for: pageChange.current)
            })
            .disposed(by: disposeBag)

        // State binding - isCompleted
        reactor.state
            .map { $0.isCompleted }
            .distinctUntilChanged()
            .filter { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
    }

    private func navigateToPage(from previousPage: Int, to currentPage: Int) {
        guard currentPage >= 0, currentPage < pages.count else { return }
        // 스와이프로 이미 페이지가 변경된 경우, 불필요한 애니메이션 방지
        guard let currentVC = pageViewController.viewControllers?.first as? TutorialPageViewController,
              currentVC.pageIndex != currentPage else {
            return
        }
        let direction: UIPageViewController.NavigationDirection = currentPage > previousPage ? .forward : .reverse
        pageViewController.setViewControllers(
            [pages[currentPage]],
            direction: direction,
            animated: true
        )
    }

    private func updateButtonTitle(for pageIndex: Int) {
        let isLastPage = pageIndex == pages.count - 1
        let title = isLastPage ? "Tutorial.start".localized : "Tutorial.next".localized
        nextButton.setTitle(title, for: .normal)
    }
}

// MARK: - UIPageViewControllerDataSource

extension TutorialViewController: UIPageViewControllerDataSource {

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let pageVC = viewController as? TutorialPageViewController,
              pageVC.pageIndex > 0 else {
            return nil
        }
        return pages[pageVC.pageIndex - 1]
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let pageVC = viewController as? TutorialPageViewController,
              pageVC.pageIndex < pages.count - 1 else {
            return nil
        }
        return pages[pageVC.pageIndex + 1]
    }
}

// MARK: - UIPageViewControllerDelegate

extension TutorialViewController: UIPageViewControllerDelegate {

    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed,
              let currentVC = pageViewController.viewControllers?.first as? TutorialPageViewController else {
            return
        }
        // 스와이프로 페이지 변경 시 Reactor에 상태 업데이트
        reactor.action.onNext(.setCurrentPage(currentVC.pageIndex))
    }
}

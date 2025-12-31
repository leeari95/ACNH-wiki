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

    // MARK: - Properties

    private let disposeBag = DisposeBag()
    private var reactor: TutorialReactor?

    private var pages: [TutorialPageViewController] = []
    private var currentIndex: Int = 0

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

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        setUpPages()
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
        let pageContents: [(imageName: String, title: String, description: String)] = [
            ("leaf.fill", "Tutorial.welcome.title".localized, "Tutorial.welcome.description".localized),
            ("book.fill", "Tutorial.catalog.title".localized, "Tutorial.catalog.description".localized),
            ("heart.fill", "Tutorial.collection.title".localized, "Tutorial.collection.description".localized),
            ("checkmark.seal.fill", "Tutorial.tasks.title".localized, "Tutorial.tasks.description".localized),
            ("gearshape.fill", "Tutorial.settings.title".localized, "Tutorial.settings.description".localized)
        ]

        pages = pageContents.enumerated().map { index, content in
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

    func bind(to reactor: TutorialReactor) {
        self.reactor = reactor

        // Skip button action
        skipButton.rx.tap
            .map { TutorialReactor.Action.skip }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // Next button action
        nextButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                if self.currentIndex < self.pages.count - 1 {
                    self.currentIndex += 1
                    self.pageViewController.setViewControllers(
                        [self.pages[self.currentIndex]],
                        direction: .forward,
                        animated: true
                    )
                    self.pageControl.currentPage = self.currentIndex
                    self.updateButtonTitle()
                } else {
                    reactor.action.onNext(.complete)
                }
            })
            .disposed(by: disposeBag)

        // State binding
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

    private func updateButtonTitle() {
        let isLastPage = currentIndex == pages.count - 1
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
        currentIndex = currentVC.pageIndex
        pageControl.currentPage = currentIndex
        updateButtonTitle()
    }
}

//
//  CollectionStatisticsView.swift
//  Animal-Crossing-Wiki
//
//  Created by Claude on 2026/01/01.
//

import UIKit
import RxSwift

final class CollectionStatisticsView: UIView {

    private let disposeBag = DisposeBag()

    // MARK: - UI Components

    private lazy var backgroundStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 16
        return stackView
    }()

    private lazy var totalProgressView: TotalProgressView = {
        let view = TotalProgressView()
        return view
    }()

    private lazy var categoryGridView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        return stackView
    }()

    private lazy var activityIndicator: LoadingView = {
        let activityIndicator = LoadingView(backgroundColor: .acSecondaryBackground, alpha: 1)
        return activityIndicator
    }()

    private lazy var emptyView: EmptyView = EmptyView(
        title: "Please check the network status.".localized,
        description: ""
    )

    // MARK: - Configuration

    private func configure() {
        let config = UIImage.SymbolConfiguration(scale: .small)
        let image = UIImageView(image: UIImage(systemName: "chevron.forward", withConfiguration: config))
        image.tintColor = .systemGray
        emptyView.backgroundColor = .acSecondaryBackground

        addSubviews(backgroundStackView, image, activityIndicator, emptyView)
        backgroundStackView.addArrangedSubviews(totalProgressView, categoryGridView)

        let heightAnchor = backgroundStackView.heightAnchor.constraint(equalTo: heightAnchor)
        heightAnchor.priority = .defaultHigh

        NSLayoutConstraint.activate([
            image.trailingAnchor.constraint(equalTo: trailingAnchor),
            image.centerYAnchor.constraint(equalTo: centerYAnchor),
            backgroundStackView.topAnchor.constraint(equalTo: topAnchor),
            backgroundStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundStackView.widthAnchor.constraint(equalTo: widthAnchor, constant: -25),
            heightAnchor,
            activityIndicator.widthAnchor.constraint(equalTo: widthAnchor),
            activityIndicator.topAnchor.constraint(equalTo: backgroundStackView.topAnchor),
            activityIndicator.bottomAnchor.constraint(equalTo: backgroundStackView.bottomAnchor),
            emptyView.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: centerYAnchor),
            emptyView.widthAnchor.constraint(equalTo: widthAnchor),
            emptyView.heightAnchor.constraint(equalTo: self.heightAnchor)
        ])
    }

    // MARK: - Binding

    private func bind(to reactor: CollectionStatisticsSectionReactor) {
        let tap = UITapGestureRecognizer()
        addGestureRecognizer(tap)

        Observable.just(CollectionStatisticsSectionReactor.Action.fetch)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        tap.rx.event
            .map { _ in CollectionStatisticsSectionReactor.Action.didTapSection }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)

        reactor.state.map { $0.isLoading }
            .bind(to: activityIndicator.rx.isAnimating)
            .disposed(by: disposeBag)

        reactor.state.map { $0.totalProgress }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] progress in
                self?.totalProgressView.update(progress: progress)
            }).disposed(by: disposeBag)

        reactor.state.map { $0.statistics }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] statistics in
                self?.updateCategoryGrid(with: statistics)
            }).disposed(by: disposeBag)

        Items.shared.count()
            .map { $0.isEmpty }
            .subscribe(onNext: { [weak self] isEmpty in
                self?.emptyView.isHidden = !isEmpty
                if isEmpty {
                    self?.removeGestureRecognizer(tap)
                } else {
                    self?.addGestureRecognizer(tap)
                }
            }).disposed(by: disposeBag)
    }

    private func updateCategoryGrid(with statistics: [CollectionStatisticsSectionReactor.CategoryStatistics]) {
        categoryGridView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Group museum categories (first 5)
        let museumCategories: [Category] = [.fishes, .bugs, .seaCreatures, .fossils, .art]
        let museumStats = statistics.filter { museumCategories.contains($0.category) }

        if !museumStats.isEmpty {
            let museumSection = createCategorySection(
                title: "Museum".localized,
                statistics: museumStats
            )
            categoryGridView.addArrangedSubview(museumSection)
        }

        // Furniture categories
        let furnitureCategories: [Category] = [
            .housewares, .miscellaneous, .wallMounted, .ceilingDecor,
            .wallpaper, .floors, .rugs, .other
        ]
        let furnitureStats = statistics.filter { furnitureCategories.contains($0.category) }

        if !furnitureStats.isEmpty {
            let furnitureSection = createCategorySection(
                title: "Furniture".localized,
                statistics: Array(furnitureStats.prefix(4))
            )
            categoryGridView.addArrangedSubview(furnitureSection)
        }

        // Clothing categories
        let clothingCategories: [Category] = [
            .tops, .bottoms, .dressUp, .headwear, .accessories,
            .socks, .shoes, .bags, .umbrellas, .wetSuit
        ]
        let clothingStats = statistics.filter { clothingCategories.contains($0.category) }

        if !clothingStats.isEmpty {
            let clothingSection = createCategorySection(
                title: "Clothing".localized,
                statistics: Array(clothingStats.prefix(4))
            )
            categoryGridView.addArrangedSubview(clothingSection)
        }
    }

    private func createCategorySection(
        title: String,
        statistics: [CollectionStatisticsSectionReactor.CategoryStatistics]
    ) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 4
        container.alignment = .fill

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .preferredFont(for: .caption1, weight: .semibold)
        titleLabel.textColor = .acSecondaryText

        container.addArrangedSubview(titleLabel)

        let rowStackView = UIStackView()
        rowStackView.axis = .horizontal
        rowStackView.distribution = .fillEqually
        rowStackView.spacing = 8

        for stat in statistics {
            let itemView = StatisticsItemView()
            itemView.configure(with: stat)
            rowStackView.addArrangedSubview(itemView)
        }

        container.addArrangedSubview(rowStackView)

        return container
    }
}

// MARK: - Convenience Init

extension CollectionStatisticsView {
    convenience init(viewModel: CollectionStatisticsSectionReactor) {
        self.init(frame: .zero)
        bind(to: viewModel)
        configure()
    }
}

// MARK: - TotalProgressView

private final class TotalProgressView: UIView {

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Total Collection".localized
        label.font = .preferredFont(for: .subheadline, weight: .semibold)
        label.textColor = .acText
        return label
    }()

    private lazy var progressLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(for: .caption1, weight: .medium)
        label.textColor = .acSecondaryText
        label.textAlignment = .right
        return label
    }()

    private lazy var progressBar: ProgressBar = {
        let progressBar = ProgressBar()
        progressBar.setHeight(8)
        return progressBar
    }()

    private lazy var percentageLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(for: .title2, weight: .bold)
        label.textColor = .acHeaderBackground
        label.textAlignment = .right
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        let topStack = UIStackView()
        topStack.axis = .horizontal
        topStack.distribution = .equalSpacing

        topStack.addArrangedSubviews(titleLabel, percentageLabel)

        let bottomStack = UIStackView()
        bottomStack.axis = .horizontal
        bottomStack.spacing = 8
        bottomStack.alignment = .center

        bottomStack.addArrangedSubviews(progressBar, progressLabel)

        addSubviews(topStack, bottomStack)

        NSLayoutConstraint.activate([
            topStack.topAnchor.constraint(equalTo: topAnchor),
            topStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            topStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomStack.topAnchor.constraint(equalTo: topStack.bottomAnchor, constant: 8),
            bottomStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            progressLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])
    }

    func update(progress: CollectionStatisticsSectionReactor.TotalProgress) {
        progressLabel.text = "\(progress.collectedCount) / \(progress.totalCount)"
        percentageLabel.text = "\(progress.progressPercentage)%"
        progressBar.setProgress(progress.progressRate, animated: true)
    }
}

// MARK: - StatisticsItemView

private final class StatisticsItemView: UIView {

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var progressLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(for: .caption2, weight: .medium)
        label.textColor = .acSecondaryText
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()

    private lazy var progressBar: ProgressBar = {
        let progressBar = ProgressBar()
        progressBar.setHeight(4)
        return progressBar
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 2

        stackView.addArrangedSubviews(iconImageView, progressBar, progressLabel)

        addSubviews(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            progressBar.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: 4)
        ])
    }

    func configure(with statistics: CollectionStatisticsSectionReactor.CategoryStatistics) {
        iconImageView.image = UIImage(named: statistics.category.progressIconName)
        progressLabel.text = "\(statistics.progressPercentage)%"
        progressBar.setProgress(statistics.progressRate, animated: false)
    }
}

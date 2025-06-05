//
//  CollectionProgressView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/15.
//

import UIKit
import RxSwift
import ACNHCore
import ACNHShared

final class CollectionProgressView: UIView {

    private let disposeBag = DisposeBag()

    private lazy var backgroundStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .equalCentering
        stackView.spacing = 0
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

    private func configure() {
        let config = UIImage.SymbolConfiguration(scale: .small)
        let image = UIImageView(image: UIImage(systemName: "chevron.forward", withConfiguration: config))
        image.tintColor = .systemGray
        emptyView.backgroundColor = .acSecondaryBackground
        addSubviews(backgroundStackView, image, activityIndicator, emptyView)
        backgroundStackView.addArrangedSubviews(Category.progress().map { ProgressView(category: $0) })

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

    private func bind(to reactor: CollectionProgressSectionReactor) {
        let tap = UITapGestureRecognizer()
        addGestureRecognizer(tap)

        Observable.just(CollectionProgressSectionReactor.Action.fetch)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        tap.rx.event
            .map { _ in CollectionProgressSectionReactor.Action.didTapSection }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)

        reactor.state.map { $0.isLoading }
            .bind(to: activityIndicator.rx.isAnimating)
            .disposed(by: disposeBag)

        Items.shared.count()
            .map { $0.isEmpty }
            .subscribe(onNext: { [weak self] isEmpty in
                self?.emptyView.isHidden = !isEmpty
                if isEmpty {
                    self?.removeGestureRecognizer(tap)
                } else {
                    self?.addGestureRecognizer(tap)
                }
            })
            .disposed(by: disposeBag)
    }
}

extension CollectionProgressView {
    convenience init(viewModel: CollectionProgressSectionReactor) {
        self.init(frame: .zero)
        bind(to: viewModel)
        configure()
    }
}

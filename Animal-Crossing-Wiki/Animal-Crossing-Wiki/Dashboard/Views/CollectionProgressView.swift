//
//  CollectionProgressView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/15.
//

import UIKit
import RxSwift

class CollectionProgressView: UIView {
    
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
    
    private func configure() {
        let config = UIImage.SymbolConfiguration(scale: .small)
        let image = UIImageView(image: UIImage(systemName: "chevron.forward", withConfiguration: config))
        image.tintColor = .systemGray
        addSubviews(backgroundStackView, image, activityIndicator)
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
            activityIndicator.bottomAnchor.constraint(equalTo: backgroundStackView.bottomAnchor)
        ])
    }
    
    private func bind(to viewModel: CollectionProgressSectionViewModel) {
        let tap = UITapGestureRecognizer()
        addGestureRecognizer(tap)
        let input = CollectionProgressSectionViewModel.Input(didTapSection: tap.rx.event.asObservable())
        let output = viewModel.transform(input: input, disposeBag: disposeBag)
        output.isLoading
            .bind(to: self.activityIndicator.rx.isAnimating)
            .disposed(by: disposeBag)
    }
}

extension CollectionProgressView {
    convenience init(viewModel: CollectionProgressSectionViewModel) {
        self.init(frame: .zero)
        bind(to: viewModel)
        configure()
    }
}

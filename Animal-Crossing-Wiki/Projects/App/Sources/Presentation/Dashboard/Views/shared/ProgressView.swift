//
//  ProgressView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/15.
//

import UIKit
import RxSwift

class ProgressView: UIStackView {

    private var disposeBag = DisposeBag()
    private var barHeight: CGFloat = 30

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    private lazy var progressBar: ProgressBar = {
        let progressBar = ProgressBar()
        progressBar.setHeight(barHeight/2.8)
        return progressBar
    }()

    private lazy var progressLabel: UILabel = {
        let label = UILabel()
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.font = .preferredFont(for: .footnote, weight: .semibold)
        label.textColor = .acText
        label.textAlignment = .right
        return label
    }()

    private func configure() {
        axis = .horizontal
        alignment = .center
        distribution = .fill
        spacing = 5

        addArrangedSubviews(iconImageView, progressBar, progressLabel)
        NSLayoutConstraint.activate([
            iconImageView.heightAnchor.constraint(equalToConstant: 30),
            iconImageView.widthAnchor.constraint(equalTo: iconImageView.heightAnchor),
            progressLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 46)
        ])
    }

    private func bind(to reactor: ProgressReactor) {
        Observable.just(ProgressReactor.Action.fetch)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        reactor.state.map { $0.itemInfo }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] items in
                self?.progressLabel.text = "\(items.itemCount) / \(items.maxCount)"
                self?.progressBar.setProgress(Float(items.itemCount) / Float(items.maxCount), animated: false)
            }).disposed(by: disposeBag)
    }
}

extension ProgressView {
    convenience init(category: Category, barHeight: CGFloat = 30) {
        self.init(frame: .zero)
        self.barHeight = barHeight
        self.iconImageView.image = UIImage(named: category.progressIconName)
        configure()
        bind(to: ProgressReactor(category: category))
    }

    func updateView(category: Category) {
        self.iconImageView.image = UIImage(named: category.progressIconName)
        disposeBag = DisposeBag()
        bind(to: ProgressReactor(category: category))
    }
}

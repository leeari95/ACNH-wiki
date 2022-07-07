//
//  ProgressView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/15.
//

import UIKit
import RxSwift

class ProgressView: UIStackView {
    
    private var viewModel: ProgressViewModel?
    private let disposeBag = DisposeBag()
    private var height: CGFloat = 30
    
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    private lazy var progressBar: ProgressBar = {
        let progressBar = ProgressBar()
        progressBar.setHeight(height/2.8)
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
        spacing = 10
        
        addArrangedSubviews(iconImageView, progressBar, progressLabel)
        NSLayoutConstraint.activate([
            iconImageView.heightAnchor.constraint(equalToConstant: height),
            iconImageView.widthAnchor.constraint(equalTo: iconImageView.heightAnchor)
        ])
    }
    
    private func bind() {
        let output = viewModel?.transform(disposeBag: disposeBag)
        
        output?.items
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .subscribe(onNext: { owner, items in
                owner.progressLabel.text = "\(items.itemCount) / \(items.maxCount)"
                owner.progressBar.setProgress(Float(items.itemCount) / Float(items.maxCount), animated: true)
            }).disposed(by: disposeBag)
    }
}

extension ProgressView {
    convenience init(category: Category) {
        self.init(frame: .zero)
        self.iconImageView.image = UIImage(named: category.progressIconName)
        viewModel = ProgressViewModel(category: category)
        configure()
        bind()
    }
}

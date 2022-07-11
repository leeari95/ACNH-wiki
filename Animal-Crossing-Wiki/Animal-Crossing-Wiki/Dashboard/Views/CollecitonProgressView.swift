//
//  CollecitonProgressView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/15.
//

import UIKit
import RxSwift

class CollecitonProgressView: UIView {
    
    private let disposeBag = DisposeBag()

    private lazy var backgroundStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .equalCentering
        stackView.spacing = 0
        return stackView
    }()
    
    private func configure() {
        let config = UIImage.SymbolConfiguration(scale: .small)
        let image = UIImageView(image: UIImage(systemName: "chevron.forward", withConfiguration: config))
        image.tintColor = .systemGray
        addSubviews(backgroundStackView, image)
        backgroundStackView.addArrangedSubviews(Category.progress().map { ProgressView(category: $0) })
        
        let heightAnchor = backgroundStackView.heightAnchor.constraint(equalTo: heightAnchor)
        heightAnchor.priority = .defaultHigh
        NSLayoutConstraint.activate([
            image.trailingAnchor.constraint(equalTo: trailingAnchor),
            image.centerYAnchor.constraint(equalTo: centerYAnchor),
            backgroundStackView.topAnchor.constraint(equalTo: topAnchor),
            backgroundStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundStackView.widthAnchor.constraint(equalTo: widthAnchor, constant: -25),
            heightAnchor
        ])
    }
}

extension CollecitonProgressView {
    convenience init(viewModel: CollectionProgressSectionViewModel) {
        self.init(frame: .zero)
        let tap = UITapGestureRecognizer()
        addGestureRecognizer(tap)
        let input = CollectionProgressSectionViewModel.Input(didTapSection: tap.rx.event.asObservable())
        viewModel.bind(input: input, disposeBag: disposeBag)
        configure()
    }
}

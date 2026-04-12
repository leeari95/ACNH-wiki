//
//  SectionsScrollView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/16.
//

import UIKit

final class SectionsScrollView: UIView {

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInset.bottom = 60
        scrollView.contentInsetAdjustmentBehavior = .automatic
        return scrollView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 25
        stackView.backgroundColor = .clear
        return stackView
    }()

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    private func configure() {
        backgroundColor = .acBackground
        addSubviews(scrollView)
        scrollView.addSubviews(contentStackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor)
        ])

        let heightAnchor = scrollView.heightAnchor.constraint(greaterThanOrEqualTo: contentStackView.heightAnchor)
        heightAnchor.priority = .defaultLow

        let maxWidthConstraint = contentStackView.widthAnchor.constraint(lessThanOrEqualToConstant: 700)
        maxWidthConstraint.priority = .required

        let fillWidthConstraint = contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        fillWidthConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStackView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            maxWidthConstraint,
            fillWidthConstraint,
            heightAnchor
        ])
    }
}

extension SectionsScrollView {
    convenience init(_ sections: SectionView...) {
        self.init(frame: .zero)
        contentStackView.addArrangedSubviews(sections)
    }

    func addSection(_ sections: SectionView...) {
        contentStackView.addArrangedSubviews(sections)
    }
}

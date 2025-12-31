//
//  SectionView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/14.
//

import UIKit

final class SectionView: UIView {

    private lazy var headerView: SectionHeaderView = {
        let headerView = SectionHeaderView()
        return headerView
    }()

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .acSecondaryBackground
        view.layer.cornerRadius = 14
        return view
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .acSecondaryBackground
        return view
    }()
}

extension SectionView {
    convenience init(title: String, iconName: String, contentView: UIView) {
        self.init(frame: .zero)
        headerView.setUp(title: title, iconName: iconName)
        setUpContent(contentView)
        configure()
        setupAccessibility(title: title)
    }

    convenience init(title: String, category: Category, contentView: UIView) {
        self.init(frame: .zero)
        headerView.setUp(title: title, category: category)
        setUpContent(contentView)
        configure()
        setupAccessibility(title: title)
    }

    convenience init(contentView: UIView) {
        self.init(frame: .zero)
        setUpContent(contentView)
        configureContainer()
    }

    private func setupAccessibility(title: String) {
        headerView.isAccessibilityElement = true
        headerView.accessibilityLabel = title
        headerView.accessibilityTraits = .header

        // 컨테이너뷰는 접근성 컨테이너로 설정
        containerView.accessibilityElements = [contentView]
        containerView.shouldGroupAccessibilityChildren = true
    }

    private func configureHeader() {
        addSubviews(headerView)
        let height = heightAnchor.constraint(equalToConstant: 80)
        height.priority = .defaultLow
        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            headerView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            headerView.heightAnchor.constraint(equalToConstant: 30),
            height
        ])
    }

    private func configureContainer() {
        addSubviews(containerView)
        var topAnchor = containerView.topAnchor.constraint(equalTo: self.topAnchor)
        if subviews.contains(headerView) {
            topAnchor = containerView.topAnchor.constraint(equalTo: self.topAnchor, constant: 40)
        }
        NSLayoutConstraint.activate([
            topAnchor,
            bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
    }

    private func configure() {
        configureHeader()
        configureContainer()
    }

    private func setUpContent(_ view: UIView) {
        contentView = view

        containerView.addSubviews(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 14),
            contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14)
        ])
    }
}

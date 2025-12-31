//
//  TurnipSummaryView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import UIKit

final class TurnipSummaryView: UIView {

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Expected Price Range".localized
        label.font = .preferredFont(for: .headline, weight: .bold)
        label.textColor = .acText
        return label
    }()

    private lazy var minPriceView: PriceLabelView = {
        let view = PriceLabelView()
        view.configure(title: "Min".localized, color: .systemRed)
        return view
    }()

    private lazy var maxPriceView: PriceLabelView = {
        let view = PriceLabelView()
        view.configure(title: "Max".localized, color: .systemGreen)
        return view
    }()

    private lazy var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .acSecondaryBackground
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpViews() {
        backgroundColor = .acSecondaryBackground
        layer.cornerRadius = 16

        let priceStack = UIStackView(arrangedSubviews: [minPriceView, separatorView, maxPriceView])
        priceStack.axis = .horizontal
        priceStack.distribution = .fillEqually
        priceStack.alignment = .center
        priceStack.spacing = 8

        let mainStack = UIStackView(arrangedSubviews: [titleLabel, priceStack])
        mainStack.axis = .vertical
        mainStack.spacing = 16
        mainStack.alignment = .center

        addSubviews(mainStack)

        NSLayoutConstraint.activate([
            separatorView.widthAnchor.constraint(equalToConstant: 1),
            separatorView.heightAnchor.constraint(equalToConstant: 40),

            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
    }

    func configure(minPrice: Int, maxPrice: Int) {
        minPriceView.setPrice(minPrice)
        maxPriceView.setPrice(maxPrice)
    }
}

// MARK: - PriceLabelView

private final class PriceLabelView: UIView {

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(for: .footnote, weight: .medium)
        label.textColor = .acSecondaryText
        return label
    }()

    private lazy var priceLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(for: .title2, weight: .bold)
        label.textColor = .acText
        return label
    }()

    private lazy var bellsLabel: UILabel = {
        let label = UILabel()
        label.text = "Bells".localized
        label.font = .preferredFont(for: .caption1, weight: .regular)
        label.textColor = .acSecondaryText
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpViews() {
        let stack = UIStackView(arrangedSubviews: [titleLabel, priceLabel, bellsLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .center

        addSubviews(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    func configure(title: String, color: UIColor) {
        titleLabel.text = title
        priceLabel.textColor = color
    }

    func setPrice(_ price: Int) {
        priceLabel.text = price > 0 ? "\(price)" : "-"
    }
}

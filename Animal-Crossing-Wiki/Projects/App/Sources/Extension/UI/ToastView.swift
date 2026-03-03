//
//  ToastView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2025/05/20.
//

import UIKit

final class ToastView: UIView {

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.startAnimating()
        return indicator
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()

    private var topConstraint: NSLayoutConstraint?

    init(message: String) {
        super.init(frame: .zero)
        messageLabel.text = message
        configure()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        backgroundColor = .secondarySystemBackground
        clipsToBounds = false
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4

        let stackView = UIStackView(arrangedSubviews: [activityIndicator, messageLabel])
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center

        addSubviews(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    func show(in window: UIWindow) {
        translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(self)

        let topConstraint = topAnchor.constraint(
            equalTo: window.safeAreaLayoutGuide.topAnchor,
            constant: -80
        )
        self.topConstraint = topConstraint

        NSLayoutConstraint.activate([
            topConstraint,
            centerXAnchor.constraint(equalTo: window.centerXAnchor)
        ])

        window.layoutIfNeeded()

        topConstraint.constant = 8
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut
        ) {
            window.layoutIfNeeded()
        }
    }

    func dismiss() {
        topConstraint?.constant = -80
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            options: .curveEaseIn,
            animations: {
                self.superview?.layoutIfNeeded()
                self.alpha = 0
            },
            completion: { _ in
                self.removeFromSuperview()
            }
        )
    }
}

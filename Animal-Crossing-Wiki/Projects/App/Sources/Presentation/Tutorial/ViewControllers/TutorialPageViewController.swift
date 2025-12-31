//
//  TutorialPageViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Claude on 2026/01/01.
//

import UIKit

final class TutorialPageViewController: UIViewController {

    // MARK: - Properties

    let pageIndex: Int
    private let imageName: String
    private let titleText: String
    private let descriptionText: String

    // MARK: - UI Components

    private lazy var containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 32
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var iconContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .acHeaderBackground.withAlphaComponent(0.15)
        view.layer.cornerRadius = 60
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .acHeaderBackground
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(for: .title1, weight: .bold)
        label.textColor = .acText
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Initialization

    init(imageName: String, titleText: String, descriptionText: String, pageIndex: Int) {
        self.imageName = imageName
        self.titleText = titleText
        self.descriptionText = descriptionText
        self.pageIndex = pageIndex
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        configure()
    }

    // MARK: - Setup

    private func setUpViews() {
        view.backgroundColor = .acBackground

        view.addSubview(containerStackView)

        iconContainerView.addSubview(iconImageView)
        containerStackView.addArrangedSubview(iconContainerView)
        containerStackView.addArrangedSubview(titleLabel)
        containerStackView.addArrangedSubview(descriptionLabel)

        containerStackView.setCustomSpacing(48, after: iconContainerView)

        NSLayoutConstraint.activate([
            containerStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            containerStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            containerStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            iconContainerView.widthAnchor.constraint(equalToConstant: 120),
            iconContainerView.heightAnchor.constraint(equalToConstant: 120),

            iconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 56),
            iconImageView.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    private func configure() {
        iconImageView.image = UIImage(systemName: imageName)
        titleLabel.text = titleText
        descriptionLabel.text = descriptionText
    }
}

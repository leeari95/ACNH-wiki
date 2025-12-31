//
//  EventCalendarView.swift
//  Animal-Crossing-Wiki
//
//  Created by Claude on 2024/01/01.
//

import UIKit
import RxSwift

final class EventCalendarView: UIView {

    private let disposeBag = DisposeBag()
    private var heightConstraint: NSLayoutConstraint!

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 8
        return stackView
    }()

    private lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No events this month".localized
        label.textColor = .acSecondaryText
        label.font = .preferredFont(for: .callout, weight: .regular)
        label.textAlignment = .center
        return label
    }()

    private func configure() {
        addSubviews(stackView, emptyLabel)

        heightConstraint = heightAnchor.constraint(greaterThanOrEqualToConstant: 40)
        heightConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            emptyLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightConstraint
        ])
    }

    func bind(to reactor: EventCalendarSectionReactor) {
        Observable.just(EventCalendarSectionReactor.Action.fetch)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        reactor.state.map { $0.events }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] events in
                self?.updateUI(with: events)
            }).disposed(by: disposeBag)
    }

    private func updateUI(with events: [ACNHEvent]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if events.isEmpty {
            emptyLabel.isHidden = false
            stackView.isHidden = true
        } else {
            emptyLabel.isHidden = true
            stackView.isHidden = false

            events.forEach { event in
                let eventRow = createEventRow(for: event)
                stackView.addArrangedSubview(eventRow)
            }
        }
    }

    private func createEventRow(for event: ACNHEvent) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = event.isOngoing ? .acHeaderBackground.withAlphaComponent(0.3) : .clear
        containerView.layer.cornerRadius = 8

        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: event.iconName)
        iconImageView.tintColor = event.isOngoing ? .acNavigationBarTint : .acSecondaryText
        iconImageView.contentMode = .scaleAspectFit

        let nameLabel = UILabel()
        nameLabel.text = event.name.localized
        nameLabel.textColor = event.isOngoing ? .acText : .acSecondaryText
        nameLabel.font = .preferredFont(for: .callout, weight: event.isOngoing ? .semibold : .regular)

        let dateLabel = UILabel()
        dateLabel.text = event.dateDisplayString
        dateLabel.textColor = .acSecondaryText
        dateLabel.font = .preferredFont(for: .caption1, weight: .regular)
        dateLabel.textAlignment = .right

        let statusLabel = UILabel()
        if event.isOngoing {
            statusLabel.text = "Ongoing".localized
            statusLabel.textColor = .acNavigationBarTint
            statusLabel.font = .preferredFont(for: .caption2, weight: .bold)
            statusLabel.backgroundColor = .acNavigationBarTint.withAlphaComponent(0.2)
            statusLabel.layer.cornerRadius = 4
            statusLabel.clipsToBounds = true
            statusLabel.textAlignment = .center
        }
        statusLabel.isHidden = !event.isOngoing

        containerView.addSubviews(iconImageView, nameLabel, dateLabel, statusLabel)

        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),

            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),

            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),

            statusLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 8),
            statusLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            statusLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 50),
            statusLabel.heightAnchor.constraint(equalToConstant: 18),

            dateLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            dateLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            dateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: statusLabel.trailingAnchor, constant: 8)
        ])

        // Add bottom constraint for name label
        let bottomConstraint = nameLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
        bottomConstraint.priority = .defaultHigh
        bottomConstraint.isActive = true

        return containerView
    }
}

extension EventCalendarView {

    convenience init(_ reactor: EventCalendarSectionReactor) {
        self.init(frame: .zero)
        bind(to: reactor)
        configure()
    }
}

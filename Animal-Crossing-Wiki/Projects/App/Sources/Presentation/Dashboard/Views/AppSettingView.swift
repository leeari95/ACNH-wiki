//
//  AppSettingView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/12.
//

import UIKit
import RxSwift

final class AppSettingView: UIView {

    private let disposeBag = DisposeBag()
    private let resetTapGesture = UITapGestureRecognizer()

    private lazy var backgroundStackView: UIStackView = {
        let stackView = UIStackView(
            axis: .vertical,
            alignment: .fill,
            distribution: .fill,
            spacing: 4
        )
        return stackView
    }()

    private lazy var hapticSwitch: UISwitch = {
        let hapticSwitch = UISwitch()
        hapticSwitch.isOn = HapticManager.shared.mode == .on
        hapticSwitch.setContentHuggingPriority(.required, for: .horizontal)
        return hapticSwitch
    }()

    private lazy var notificationSwitch: UISwitch = {
        let notificationSwitch = UISwitch()
        notificationSwitch.isOn = NotificationManager.shared.mode == .on
        notificationSwitch.setContentHuggingPriority(.required, for: .horizontal)
        return notificationSwitch
    }()

    private func configure() {
        addSubviews(backgroundStackView)

        NSLayoutConstraint.activate([
            backgroundStackView.topAnchor.constraint(equalTo: topAnchor),
            backgroundStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundStackView.widthAnchor.constraint(equalTo: widthAnchor),
            backgroundStackView.heightAnchor.constraint(equalTo: heightAnchor)
        ])
        let resetView = InfoContentView(title: "Data reset".localized)
        backgroundStackView.addArrangedSubviews(
            InfoContentView(title: "System haptic".localized, contentView: hapticSwitch),
            InfoContentView(title: "Rare creature notification".localized, contentView: notificationSwitch),
            resetView
        )
        resetView.addGestureRecognizer(resetTapGesture)
    }

    func bind(to reactor: AppSettingReactor) {
        hapticSwitch.rx.controlEvent(.valueChanged)
            .map { AppSettingReactor.Action.toggleHaptic }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)

        notificationSwitch.rx.controlEvent(.valueChanged)
            .map { AppSettingReactor.Action.toggleNotification }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)

        resetTapGesture.rx.event
            .map { _ in AppSettingReactor.Action.reset }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        reactor.state.map { $0.currentHapticState }
            .distinctUntilChanged()
            .bind(to: hapticSwitch.rx.isOn)
            .disposed(by: disposeBag)

        reactor.state.map { $0.currentNotificationState }
            .distinctUntilChanged()
            .bind(to: notificationSwitch.rx.isOn)
            .disposed(by: disposeBag)
    }
}

extension AppSettingView {
    convenience init(reactor: AppSettingReactor) {
        self.init(frame: .zero)
        configure()
        bind(to: reactor)
    }
}

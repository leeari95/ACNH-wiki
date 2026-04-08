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
    private let recoverTapGesture = UITapGestureRecognizer() // TEMPORARY: Recovery
    private lazy var recoveryIndicator = UIActivityIndicatorView(style: .medium) // TEMPORARY: Recovery

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
        hapticSwitch.isOn = HapticManager.shared.mode == .on ? true : false
        hapticSwitch.setContentHuggingPriority(.required, for: .horizontal)
        return hapticSwitch
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
        // TEMPORARY: Recovery
        let recoverView = InfoContentView(
            title: "Recover data from iCloud".localized,
            contentView: recoveryIndicator
        )
        backgroundStackView.addArrangedSubviews(
            InfoContentView(title: "System haptic".localized, contentView: hapticSwitch),
            recoverView,
            resetView
        )
        resetView.addGestureRecognizer(resetTapGesture)
        recoverView.addGestureRecognizer(recoverTapGesture) // TEMPORARY: Recovery
    }

    func bind(to reactor: AppSettingReactor) {
        hapticSwitch.rx.controlEvent(.valueChanged)
            .map { AppSettingReactor.Action.toggleSwitch }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)

        resetTapGesture.rx.event
            .map { _ in AppSettingReactor.Action.reset }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        reactor.state.map { $0.currentHapticState }
            .bind(to: hapticSwitch.rx.isOn)
            .disposed(by: disposeBag)

        // TEMPORARY: Recovery
        recoverTapGesture.rx.event
            .map { _ in AppSettingReactor.Action.recoverFromCloud }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // TEMPORARY: Recovery — activity indicator
        reactor.state.map { $0.isRecoveryInProgress }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] inProgress in
                if inProgress {
                    self?.recoveryIndicator.startAnimating()
                } else {
                    self?.recoveryIndicator.stopAnimating()
                }
            })
            .disposed(by: disposeBag)
    }
}

extension AppSettingView {
    convenience init(reactor: AppSettingReactor) {
        self.init(frame: .zero)
        bind(to: reactor)
        configure()
    }
}

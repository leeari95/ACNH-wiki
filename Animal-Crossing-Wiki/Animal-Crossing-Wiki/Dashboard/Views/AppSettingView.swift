//
//  AppSettingView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/12.
//

import UIKit
import RxSwift

class AppSettingView: UIView {
    
    private let disposeBag = DisposeBag()
    
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
        
        backgroundStackView.addArrangedSubviews(
            InfoContentView(title: "System haptic".localized, contentView: hapticSwitch)
        )
    }
    
    func bind(to reactor: AppSettingReactor) {
        hapticSwitch.rx.controlEvent(.valueChanged)
            .map { AppSettingReactor.Action.toggleSwitch }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)
        
        reactor.state.map { $0.currentHapticState }
            .bind(to: hapticSwitch.rx.isOn)
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

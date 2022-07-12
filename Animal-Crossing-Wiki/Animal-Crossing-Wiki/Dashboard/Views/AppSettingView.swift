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
    
    func bind(to viewModel: AppSettingViewModel) {
        let input = AppSettingViewModel.Input(didTapSwitch: hapticSwitch.rx.controlEvent(.valueChanged).asObservable())
        let output = viewModel.transform(input: input, disposeBag: disposeBag)
        
        output.currentHapticState
            .bind(to: hapticSwitch.rx.isOn)
            .disposed(by: disposeBag)
    }
}

extension AppSettingView {
    convenience init(viewModel: AppSettingViewModel) {
        self.init(frame: .zero)
        bind(to: viewModel)
        configure()
    }
}

//
//  PlayerView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/22.
//

import UIKit
import RxSwift

class ItemPlayerView: UIView {
    
    private let disposeBag = DisposeBag()
    
    lazy var playButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(font: UIFont.preferredFont(for: .largeTitle, weight: .bold))
        button.setImage(UIImage(systemName: "play.fill")?.withConfiguration(config), for: .normal)
        button.tintColor = .acText
        return button
    }()
    
    convenience init() {
        self.init(frame: .zero)
        configure()
    }
    
    private func configure() {
        addSubviews(playButton)
        
        NSLayoutConstraint.activate([
            playButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            playButton.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            playButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            playButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            playButton.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}

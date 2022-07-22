//
//  PlayerViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/21.
//

import UIKit
import RxSwift
import RxCocoa

class PlayerViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    
    private lazy var visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
    private lazy var maximizeView = MaximizePlayerView()
    private lazy var minimizeView = MinimizePlayerView()
    
    private let minimizeViewTap = UITapGestureRecognizer()
    private let dragGesture = UIPanGestureRecognizer()

    override func loadView() {
        super.loadView()
        view = visualEffectView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func configure(tabBarHeight: CGFloat) {
        maximizeView.isHidden = true
        visualEffectView.contentView.addSubviews(minimizeView, maximizeView)
        NSLayoutConstraint.activate([
            minimizeView.topAnchor.constraint(equalTo: visualEffectView.topAnchor),
            minimizeView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor, constant: 20),
            minimizeView.widthAnchor.constraint(equalTo: visualEffectView.widthAnchor, constant: -40),
            minimizeView.bottomAnchor.constraint(greaterThanOrEqualTo: visualEffectView.bottomAnchor, constant: -tabBarHeight),
            maximizeView.topAnchor.constraint(equalTo: visualEffectView.topAnchor, constant: 10),
            maximizeView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor),
            maximizeView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
            maximizeView.bottomAnchor.constraint(greaterThanOrEqualTo: visualEffectView.bottomAnchor, constant: -30 + -tabBarHeight)
        ])
        
        minimizeView.addGestureRecognizer(minimizeViewTap)
        visualEffectView.addGestureRecognizer(dragGesture)
    }
    
    func bind(to viewModel: PlayerViewModel) {
        let input = PlayerViewModel.Input(
            didTapMiniPlayer: minimizeViewTap.rx.event.map { _ in }.asObservable(),
            didTapFoldingButton: maximizeView.foldingButton.rx.tap.asObservable(),
            dragGesture: dragGesture.rx.event.map { gestureRecognizer -> Bool? in
                let velocity = gestureRecognizer.velocity(in: self.visualEffectView)
                if gestureRecognizer.state == .ended {
                    if velocity.y < 0 {
                        return true
                    } else if velocity.y > 300 {
                        return false
                    }
                }
                return nil
            }.asObservable(),
            didTapCancel: minimizeView.cancelButton.rx.tap.asObservable(),
            didTapPlayButton: [
                minimizeView.playButton.rx.tap.asObservable(),
                maximizeView.playButton.rx.tap.asObservable()
            ],
            didTapNextButton: [
                minimizeView.nextButton.rx.tap.asObservable(),
                maximizeView.nextButton.rx.tap.asObservable()
            ],
            didTapPrevButton: maximizeView.previousButton.rx.tap.asObservable()
        )
        let output = viewModel.transform(input: input, disposeBag: disposeBag)
        
        output.isMinimized
            .compactMap { $0 }
            .subscribe(onNext: { isMinimized in
                if isMinimized {
                    UIView.animate(withDuration: 0.25) {
                        self.maximizeView.alpha = 0
                        self.minimizeView.alpha = 1
                    } completion: { _ in
                        self.maximizeView.isHidden = true
                        self.minimizeView.isHidden = false
                    }
                } else {
                    UIView.animate(withDuration: 0.25) {
                        self.maximizeView.alpha = 1
                        self.minimizeView.alpha = 0
                    } completion: { _ in
                        self.maximizeView.isHidden = false
                        self.minimizeView.isHidden = true
                    }
                }
            }).disposed(by: disposeBag)
        
    }
}

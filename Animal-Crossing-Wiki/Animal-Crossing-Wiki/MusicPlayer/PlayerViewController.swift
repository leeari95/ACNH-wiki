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
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.registerNib(SongRow.self)
        return tableView
    }()
    
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
        tableView.isHidden = true
        visualEffectView.contentView.addSubviews(minimizeView, maximizeView, tableView)
        NSLayoutConstraint.activate([
            minimizeView.topAnchor.constraint(equalTo: visualEffectView.topAnchor),
            minimizeView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor, constant: 20),
            minimizeView.widthAnchor.constraint(equalTo: visualEffectView.widthAnchor, constant: -40),
            minimizeView.heightAnchor.constraint(equalToConstant: 60),
            tableView.topAnchor.constraint(equalTo: minimizeView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor),
            tableView.widthAnchor.constraint(equalTo: visualEffectView.widthAnchor),
            tableView.heightAnchor.constraint(equalToConstant: 457),
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
            dragGesture: dragGesture.rx.event
                .withUnretained(self)
                .map { owner, gestureRecognizer -> Bool? in
                let velocity = gestureRecognizer.velocity(in: owner.visualEffectView)
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
            didTapPrevButton: maximizeView.previousButton.rx.tap.asObservable(),
            didTapPlayList: maximizeView.listButton.rx.tap.asObservable(),
            seletedSong: tableView.rx.modelSelected(Item.self).asObservable(),
            didTapShuffle: maximizeView.shuffleButton.rx.tap.asObservable(),
            didTapRepeat: maximizeView.repeatButton.rx.tap.asObservable()
        )
        let output = viewModel.transform(input: input, disposeBag: disposeBag)
        
        output.playerMode
            .compactMap { $0 }
            .withUnretained(self)
            .subscribe(onNext: { owner, playerMode in
                switch playerMode {
                case .large:
                    UIView.animate(withDuration: 0.25) {
                        owner.maximizeView.alpha = 1
                        owner.minimizeView.alpha = 0
                        owner.tableView.alpha = 0
                    } completion: { _ in
                        owner.maximizeView.isHidden = false
                        owner.minimizeView.isHidden = true
                        owner.tableView.isHidden = true
                    }
                case .small:
                    UIView.animate(withDuration: 0.25) {
                        owner.maximizeView.alpha = 0
                        owner.minimizeView.alpha = 1
                        owner.tableView.alpha = 0
                    } completion: { _ in
                        owner.maximizeView.isHidden = true
                        owner.tableView.isHidden = true
                        owner.minimizeView.isHidden = false
                    }
                case .list:
                    UIView.animate(withDuration: 0.25) {
                        owner.maximizeView.alpha = 0
                        owner.minimizeView.alpha = 1
                        owner.tableView.alpha = 1
                    } completion: { _ in
                        owner.maximizeView.isHidden = true
                        owner.tableView.isHidden = false
                        owner.minimizeView.isHidden = false
                    }
                }
            }).disposed(by: disposeBag)
        
        output.songs
            .bind(to: tableView.rx.items(cellIdentifier: SongRow.className, cellType: SongRow.self)) { _, item, cell in
                cell.setUp(to: item)
            }.disposed(by: disposeBag)
        
        MusicPlayerManager.shared.playingSongIndex
            .compactMap { $0 }
            .map { IndexPath(row: $0, section: .zero) }
            .withUnretained(self)
            .subscribe(onNext: { owner, indexPath in
                owner.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
            }).disposed(by: disposeBag)
    }
}

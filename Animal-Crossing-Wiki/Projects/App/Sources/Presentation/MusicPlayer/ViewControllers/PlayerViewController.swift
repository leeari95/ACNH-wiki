//
//  PlayerViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/21.
//

import UIKit
import RxSwift
import RxCocoa
import ACNHCore
import ACNHShared

final class PlayerViewController: UIViewController {

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

    func bind(to reactor: PlayerReactor) {
        Observable.just(PlayerReactor.Action.fetch)
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)

        minimizeViewTap.rx.event.map { _ in }
            .map { PlayerReactor.Action.didTapMiniPlayer }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)

        maximizeView.foldingButton.rx.tap
            .map { PlayerReactor.Action.folding }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)

        dragGesture.rx.event
            .map { [weak self] gestureRecognizer -> Bool? in
                let velocity = gestureRecognizer.velocity(in: self?.visualEffectView)
                if gestureRecognizer.state == .ended {
                    if velocity.y < 0 {
                        return true
                    } else if velocity.y > 300 {
                        return false
                    }
                }
                return nil
            }.map { PlayerReactor.Action.dragGesture($0) }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)

        minimizeView.cancelButton.rx.tap
            .map { PlayerReactor.Action.cancel }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)

        Observable.merge(
            minimizeView.playButton.rx.tap.asObservable(),
            maximizeView.playButton.rx.tap.asObservable()
        ).map { PlayerReactor.Action.play }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)

        Observable.merge(
            minimizeView.nextButton.rx.tap.asObservable(),
            maximizeView.nextButton.rx.tap.asObservable()
        ).map { PlayerReactor.Action.next }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)

        maximizeView.previousButton.rx.tap
            .map { PlayerReactor.Action.prev }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)

        maximizeView.listButton.rx.tap
            .map { PlayerReactor.Action.playerList }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)

        tableView.rx.modelSelected(Item.self)
            .map { PlayerReactor.Action.selectedSong($0) }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)

        maximizeView.shuffleButton.rx.tap
            .map { PlayerReactor.Action.shuffle }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)

        maximizeView.repeatButton.rx.tap
            .map { PlayerReactor.Action.fullRepeat }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)

        reactor.state.map { $0.playerMode }
            .subscribe(onNext: { [weak self] playerMode in
                switch playerMode {
                case .large:
                    UIView.animate(withDuration: 0.25) {
                        self?.maximizeView.alpha = 1
                        self?.minimizeView.alpha = 0
                        self?.tableView.alpha = 0
                    } completion: { _ in
                        self?.maximizeView.isHidden = false
                        self?.minimizeView.isHidden = true
                        self?.tableView.isHidden = true
                    }
                case .small:
                    UIView.animate(withDuration: 0.25) {
                        self?.maximizeView.alpha = 0
                        self?.minimizeView.alpha = 1
                        self?.tableView.alpha = 0
                    } completion: { _ in
                        self?.maximizeView.isHidden = true
                        self?.tableView.isHidden = true
                        self?.minimizeView.isHidden = false
                    }
                case .list:
                    UIView.animate(withDuration: 0.25) {
                        self?.maximizeView.alpha = 0
                        self?.minimizeView.alpha = 1
                        self?.tableView.alpha = 1
                    } completion: { _ in
                        self?.maximizeView.isHidden = true
                        self?.tableView.isHidden = false
                        self?.minimizeView.isHidden = false
                    }
                }
            }).disposed(by: disposeBag)

        reactor.state.map { $0.songs }
            .bind(to: tableView.rx.items(cellIdentifier: SongRow.className, cellType: SongRow.self)) { _, item, cell in
                cell.setUp(to: item)
            }.disposed(by: disposeBag)

        reactor.state.map { $0.songs }
            .filter { $0.isEmpty == false }
            .flatMapLatest { _ in
                MusicPlayerManager.shared.playingSongIndex
                    .compactMap { $0 }
                    .map { IndexPath(row: $0, section: .zero) }
            }
            .subscribe(onNext: { [weak self] indexPath in
                self?.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
            })
            .disposed(by: disposeBag)

    }
}

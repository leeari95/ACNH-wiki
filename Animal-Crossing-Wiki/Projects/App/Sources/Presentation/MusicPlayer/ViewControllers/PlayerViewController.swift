//
//  PlayerViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/21.
//

import UIKit
import RxSwift
import RxCocoa

final class PlayerViewController: UIViewController {

    private let disposeBag = DisposeBag()
    private var previousPlayerMode: PlayerMode = .small

    private lazy var containerView = UIView()
    private lazy var maximizeView = MaximizePlayerView()
    private lazy var minimizeView = MinimizePlayerView()

    private let minimizeViewTap = UITapGestureRecognizer()
    private let dragGesture = UIPanGestureRecognizer()

    override func loadView() {
        super.loadView()
        view = containerView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.clipsToBounds = true
        maximizeView.tableView.registerNib(SongRow.self)
    }

    func configure() {
        maximizeView.isHidden = true
        containerView.addSubviews(minimizeView, maximizeView)
        NSLayoutConstraint.activate([
            minimizeView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            minimizeView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            minimizeView.heightAnchor.constraint(equalToConstant: 64),
            maximizeView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            maximizeView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            maximizeView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            maximizeView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
        ])

        minimizeView.addGestureRecognizer(minimizeViewTap)
        containerView.addGestureRecognizer(dragGesture)
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
                let velocity = gestureRecognizer.velocity(in: self?.containerView)
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

        maximizeView.backButton.rx.tap
            .map { PlayerReactor.Action.didTapMiniPlayer }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)

        maximizeView.tableView.rx.modelSelected(Item.self)
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
                guard let owner = self else {
                    return
                }
                let previousMode = owner.previousPlayerMode
                owner.previousPlayerMode = playerMode

                switch playerMode {
                case .large:
                    owner.maximizeView.showPlayerContent()
                    owner.minimizeView.isHidden = false
                    owner.maximizeView.isHidden = false

                    // 리스트 → 라지: 내부 컨텐츠만 전환 (스케일 애니메이션 없음)
                    if previousMode == .list {
                        return
                    }

                    // 스몰 → 라지: 스케일 애니메이션 적용
                    owner.maximizeView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                    UIView.animate(
                        withDuration: 0.5,
                        delay: 0,
                        usingSpringWithDamping: 0.8,
                        initialSpringVelocity: 0.5,
                        options: .curveEaseInOut
                    ) {
                        owner.maximizeView.alpha = 1
                        owner.maximizeView.transform = .identity
                        owner.minimizeView.alpha = 0
                    } completion: { _ in
                        owner.minimizeView.isHidden = true
                    }
                case .small:
                    owner.maximizeView.showPlayerContent()
                    owner.minimizeView.isHidden = false
                    owner.minimizeView.alpha = 0
                    UIView.animate(
                        withDuration: 0.5,
                        delay: 0,
                        usingSpringWithDamping: 0.8,
                        initialSpringVelocity: 0.5,
                        options: .curveEaseInOut
                    ) {
                        owner.maximizeView.alpha = 0
                        owner.maximizeView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                        owner.minimizeView.alpha = 1
                    } completion: { _ in
                        owner.maximizeView.isHidden = true
                        owner.maximizeView.transform = .identity
                    }
                case .list:
                    owner.maximizeView.showListContent()
                    owner.minimizeView.isHidden = false
                    owner.maximizeView.isHidden = false

                    // 라지 → 리스트: 내부 컨텐츠만 전환 (스케일 애니메이션 없음)
                    if previousMode == .large {
                        UIView.animate(withDuration: 0.25) {
                            owner.minimizeView.alpha = 0
                        } completion: { _ in
                            owner.minimizeView.isHidden = true
                        }
                        return
                    }

                    // 스몰 → 리스트: 스케일 애니메이션 적용
                    owner.maximizeView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                    UIView.animate(
                        withDuration: 0.5,
                        delay: 0,
                        usingSpringWithDamping: 0.8,
                        initialSpringVelocity: 0.5,
                        options: .curveEaseInOut
                    ) {
                        owner.maximizeView.alpha = 1
                        owner.maximizeView.transform = .identity
                        owner.minimizeView.alpha = 0
                    } completion: { _ in
                        owner.minimizeView.isHidden = true
                    }
                }
            }).disposed(by: disposeBag)

        reactor.state.map { $0.songs }
            .bind(to: maximizeView.tableView.rx.items(cellIdentifier: SongRow.className, cellType: SongRow.self)) { _, item, cell in
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
                self?.maximizeView.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
            })
            .disposed(by: disposeBag)

    }
}

//
//  VillagersCell.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/29.
//

import UIKit
import RxSwift
import RxCocoa

final class VillagersCell: UICollectionViewCell {

    private var disposeBag = DisposeBag()
    private var characterName: String?
    private var isLiked: Bool = false
    private var isResident: Bool = false
    private var isNPC: Bool = false
    private var hasReceivedInitialLikeState: Bool = false
    private var hasReceivedInitialResidentState: Bool = false

    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var houseButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .acSecondaryBackground
        contentView.layer.cornerRadius = 14
        nameLabel.font = .preferredFont(for: .footnote, weight: .semibold)
        nameLabel.adjustsFontForContentSizeCategory = true
        likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
        likeButton.setTitle(nil, for: .normal)
        houseButton.setImage(UIImage(systemName: "house"), for: .normal)
        houseButton.setTitle(nil, for: .normal)
        setupAccessibility()
    }

    private func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityTraits = .button
        likeButton.isAccessibilityElement = false
        houseButton.isAccessibilityElement = false
        updateAccessibilityCustomActions()
    }

    private func updateAccessibilityCustomActions() {
        var actions: [UIAccessibilityCustomAction] = []

        // 좋아요 토글 액션
        let likeActionName = isLiked ? "remove_from_favorites".localized : "add_to_favorites".localized
        let likeAction = UIAccessibilityCustomAction(name: likeActionName) { [weak self] _ in
            self?.likeButton.sendActions(for: .touchUpInside)
            return true
        }
        actions.append(likeAction)

        // 거주자 토글 액션 (NPC가 아닌 경우에만)
        if !isNPC {
            let residentActionName = isResident ? "remove_from_residents".localized : "add_to_residents".localized
            let residentAction = UIAccessibilityCustomAction(name: residentActionName) { [weak self] _ in
                self?.houseButton.sendActions(for: .touchUpInside)
                return true
            }
            actions.append(residentAction)
        }

        accessibilityCustomActions = actions
    }

    private func updateAccessibilityLabel() {
        guard let name = characterName else {
            accessibilityLabel = nil
            accessibilityHint = nil
            return
        }

        var statusParts: [String] = []

        if isLiked {
            statusParts.append("liked".localized)
        }

        if !isNPC && isResident {
            statusParts.append("resident".localized)
        }

        let status = statusParts.isEmpty ? "" : ", " + statusParts.joined(separator: ", ")
        accessibilityLabel = "\(name)\(status)"
        accessibilityHint = "double_tap_for_details".localized
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconImage.kf.cancelDownloadTask()
        likeButton.setImage(nil, for: .normal)
        likeButton.setTitle(nil, for: .normal)
        houseButton.setImage(nil, for: .normal)
        houseButton.setTitle(nil, for: .normal)
        disposeBag = DisposeBag()
        characterName = nil
        isLiked = false
        isResident = false
        isNPC = false
        hasReceivedInitialLikeState = false
        hasReceivedInitialResidentState = false
        updateAccessibilityLabel()
    }
    
    func setUp(_ npc: NPC) {
        iconImage.setImage(with: npc.iconImage)
        let localizedName = npc.translations.localizedName()
        nameLabel.text = localizedName
        characterName = localizedName
        isNPC = true
        updateAccessibilityLabel()
        bind(reactor: NPCCellReactor(npc: npc))
        houseButton.isHidden = true
        likeButton.isHidden = false
    }

    func setUp(_ villager: Villager) {
        iconImage.setImage(with: villager.iconImage)
        let localizedName = villager.translations.localizedName()
        nameLabel.text = localizedName
        characterName = localizedName
        isNPC = false
        updateAccessibilityLabel()
        bind(reactor: VillagersCellReactor(villager: villager))
        houseButton.isHidden = false
        likeButton.isHidden = false
    }

    private func bind(reactor: VillagersCellReactor) {
        Observable.just(VillagersCellReactor.Action.fetch)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        likeButton.rx.tap
            .map { VillagersCellReactor.Action.like }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)

        houseButton.rx.tap
            .map { VillagersCellReactor.Action.home }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)

        reactor.state.map { $0.isLiked }
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLiked in
                guard let self = self else { return }
                let previousState = self.isLiked
                let isInitialState = !self.hasReceivedInitialLikeState
                self.hasReceivedInitialLikeState = true
                self.isLiked = isLiked
                self.updateAccessibilityLabel()
                self.updateAccessibilityCustomActions()
                self.likeButton.setImage(UIImage(systemName: isLiked ? "heart.fill" : "heart"), for: .normal)

                // 좋아요 상태 변경 시 접근성 알림 (초기 로딩 시에는 알림하지 않음)
                if !isInitialState && previousState != isLiked {
                    self.announceAccessibilityChange(
                        isAdded: isLiked,
                        addedKey: "added_to_favorites",
                        removedKey: "removed_from_favorites"
                    )
                }
            }).disposed(by: disposeBag)

        reactor.state.map { $0.isResident }
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isResident in
                guard let self = self else { return }
                let previousState = self.isResident
                let isInitialState = !self.hasReceivedInitialResidentState
                self.hasReceivedInitialResidentState = true
                self.isResident = isResident
                self.updateAccessibilityLabel()
                self.updateAccessibilityCustomActions()
                self.houseButton.setImage(UIImage(systemName: isResident ? "house.fill" : "house"), for: .normal)

                // 거주 상태 변경 시 접근성 알림 (초기 로딩 시에는 알림하지 않음)
                if !isInitialState && previousState != isResident {
                    self.announceAccessibilityChange(
                        isAdded: isResident,
                        addedKey: "added_to_residents",
                        removedKey: "removed_from_residents"
                    )
                }
            }).disposed(by: disposeBag)
    }

    private func bind(reactor: NPCCellReactor) {
        Observable.just(NPCCellReactor.Action.fetch)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        likeButton.rx.tap
            .map { NPCCellReactor.Action.like }
            .subscribe(onNext: { action in
                reactor.action.onNext(action)
            }).disposed(by: disposeBag)

        reactor.state.map { $0.isLiked }
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLiked in
                guard let self = self else { return }
                let previousState = self.isLiked
                let isInitialState = !self.hasReceivedInitialLikeState
                self.hasReceivedInitialLikeState = true
                self.isLiked = isLiked
                self.updateAccessibilityLabel()
                self.updateAccessibilityCustomActions()
                self.likeButton.setImage(UIImage(systemName: isLiked ? "heart.fill" : "heart"), for: .normal)

                // 좋아요 상태 변경 시 접근성 알림 (초기 로딩 시에는 알림하지 않음)
                if !isInitialState && previousState != isLiked {
                    self.announceAccessibilityChange(
                        isAdded: isLiked,
                        addedKey: "added_to_favorites",
                        removedKey: "removed_from_favorites"
                    )
                }
            }).disposed(by: disposeBag)
    }

    // MARK: - Accessibility Helpers

    private func announceAccessibilityChange(isAdded: Bool, addedKey: String, removedKey: String) {
        let announcement = isAdded ? addedKey.localized : removedKey.localized
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
}

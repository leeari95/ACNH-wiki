//
//  VillagersCell.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/29.
//

import UIKit
import RxSwift
import RxCocoa

class VillagersCell: UICollectionViewCell {
    
    private var disposeBag = DisposeBag()
    
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var houseButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .acSecondaryBackground
        contentView.layer.cornerRadius = 14
        nameLabel.font = .preferredFont(for: .footnote, weight: .semibold)
        likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
        houseButton.setImage(UIImage(systemName: "house"), for: .normal)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        iconImage.kf.cancelDownloadTask()
        likeButton.setImage(nil, for: .normal)
        houseButton.setImage(nil, for: .normal)
        disposeBag = DisposeBag()
    }
    
    func setUp(_ villager: Villager) {
        iconImage.setImage(with: villager.iconImage)
        nameLabel.text = villager.translations.localizedName()
        bind(reactor: VillagersCellReactor(villager: villager))
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
            .withUnretained(self)
            .subscribe(onNext: { owner, isLiked in
                owner.likeButton.setImage(UIImage(systemName: isLiked ? "heart.fill" : "heart"), for: .normal)
            }).disposed(by: disposeBag)
        
        reactor.state.map { $0.isResident }
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .subscribe(onNext: { owner, isResident in
                owner.houseButton.setImage(UIImage(systemName: isResident ? "house.fill" : "house"), for: .normal)
            }).disposed(by: disposeBag)
    }

}

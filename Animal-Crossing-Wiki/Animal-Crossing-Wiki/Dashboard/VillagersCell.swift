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
    
    private var viewModel: VillagersCellViewModel!
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
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        likeButton.setImage(nil, for: .normal)
        houseButton.setImage(nil, for: .normal)
        viewModel = nil
        disposeBag = DisposeBag()
    }
    
    func setUp(_ villager: Villager) {
        iconImage.setImage(with: villager.iconImage)
        nameLabel.text = villager.translations.localizedName()
        viewModel = VillagersCellViewModel(villager: villager)
        bind()
    }
    
    private func bind() {
        let input = VillagersCellViewModel.Input(
            didTapHeart: likeButton.rx.tap.asObservable(),
            didTapHouse: houseButton.rx.tap.asObservable()
        )
        
        let output = viewModel.transform(input: input, disposeBag: disposeBag)
        
        output.isLiked
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { isLiked in
                if isLiked {
                    self.likeButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
                } else {
                    self.likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
                }
            }).disposed(by: disposeBag)
        
        output.isResident
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { isResident in
                if isResident {
                    self.houseButton.setImage(UIImage(systemName: "house.fill"), for: .normal)
                } else {
                    self.houseButton.setImage(UIImage(systemName: "house"), for: .normal)
                }
            }).disposed(by: disposeBag)
    }

}

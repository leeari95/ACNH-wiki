//
//  VillagersRow.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/29.
//

import UIKit

class VillagersRow: UICollectionViewCell {
    
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var houseButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        nameLabel.font = .preferredFont(for: .footnote, weight: .semibold)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    func setUp(_ villager: Villager) {
        iconImage.setImage(with: villager.iconImage)
        nameLabel.text = villager.translations.localizedName()
    }

}

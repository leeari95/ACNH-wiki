//
//  VariantCell.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/14.
//

import UIKit

class VariantCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }

    func setUp(_ variant: Variant) {
        imageView.setImage(with: variant.image)
    }
}

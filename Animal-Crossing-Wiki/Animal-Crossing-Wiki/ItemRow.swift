//
//  ItemRow.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/20.
//

import UIKit

class ItemRow: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.image = nil
    }

    func setImage(icon: String) {
        imageView.image = UIImage(named: icon)
    }
    func setImage(url: String) {
        imageView.setImage(with: url)
    }
    
    func setAlpha(_ alpha: CGFloat) {
        self.imageView.alpha = alpha
    }
    
    func toggle() {
        self.imageView.alpha = imageView.alpha == 1 ? 0.5 : 1
    }
}

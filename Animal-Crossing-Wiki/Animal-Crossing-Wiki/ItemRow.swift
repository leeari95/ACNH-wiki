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
}

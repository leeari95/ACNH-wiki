//
//  VariantCell.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/14.
//

import UIKit

final class VariantCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.font = .preferredFont(for: .footnote, weight: .bold)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        titleLabel.text = nil
    }

    func setUp(imageURL: String, name: String?) {
        imageView.setImage(with: imageURL)
        titleLabel.text = name
    }
}

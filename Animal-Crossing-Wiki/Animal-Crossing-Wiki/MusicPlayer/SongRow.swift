//
//  SongRow.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/22.
//

import UIKit

class SongRow: UITableViewCell {
    
    @IBOutlet private weak var coverImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var artistLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.font = .preferredFont(for: .callout, weight: .semibold)
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .acText.withAlphaComponent(0.2)
    }
    
    override func prepareForReuse() {
        coverImageView.kf.cancelDownloadTask()
        coverImageView.image = nil
        titleLabel.text = nil
        artistLabel.text = nil
    }

    func setUp(to item: Item) {
        coverImageView.setImage(with: item.image ?? "")
        titleLabel.text = item.translations.localizedName()
        artistLabel.text = "K.K. Slider"
    }
    
}

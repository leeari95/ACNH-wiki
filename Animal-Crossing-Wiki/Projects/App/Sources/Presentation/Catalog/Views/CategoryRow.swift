//
//  CategoryRow.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/08.
//

import UIKit

class CategoryRow: UITableViewCell {

    @IBOutlet private weak var iconImage: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var itemCountLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.font = .preferredFont(for: .callout, weight: .bold)
        itemCountLabel.font = .preferredFont(forTextStyle: .footnote)
        titleLabel.textColor = .acText
        itemCountLabel.textColor = .acText
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .acText.withAlphaComponent(0.3)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconImage.image = nil
        titleLabel.text = nil
        itemCountLabel.text = nil
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func setUp(iconName: String, title: String, itemCount: Int) {
        iconImage.image = UIImage(named: iconName)
        titleLabel.text = title
        itemCountLabel.text = itemCount.decimalFormatted
    }

}

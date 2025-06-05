//
//  KeywordCell.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/14.
//

import UIKit
import ACNHCore
import ACNHShared

final class KeywordCell: UICollectionViewCell {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var stackView: UIStackView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        contentView.backgroundColor = .acNavigationBarTint
        contentView.layer.cornerRadius = 14
        contentView.layer.masksToBounds = true

        titleLabel.text = nil
        titleLabel.textColor = .white
        titleLabel.font = .preferredFont(for: .footnote, weight: .bold)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
    }

    func setUp(title: String) {
        titleLabel.text = title.lowercased().localized
    }

}

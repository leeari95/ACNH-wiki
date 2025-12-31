//
//  VariantCell.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/14.
//

import UIKit
import RxSwift
import RxCocoa

final class VariantCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!

    private(set) var disposeBag = DisposeBag()

    private lazy var checkboxButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        button.setImage(UIImage(systemName: "circle", withConfiguration: config), for: .normal)
        button.tintColor = .acNavigationBarTint
        return button
    }()

    var isVariantChecked: Bool = false {
        didSet {
            updateCheckboxAppearance()
        }
    }

    var checkboxTapped: ControlEvent<Void> {
        return checkboxButton.rx.tap
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.font = .preferredFont(for: .footnote, weight: .bold)
        setUpCheckbox()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        titleLabel.text = nil
        isVariantChecked = false
        disposeBag = DisposeBag()
    }

    private func setUpCheckbox() {
        contentView.addSubview(checkboxButton)
        NSLayoutConstraint.activate([
            checkboxButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            checkboxButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            checkboxButton.widthAnchor.constraint(equalToConstant: 24),
            checkboxButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    private func updateCheckboxAppearance() {
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let imageName = isVariantChecked ? "checkmark.circle.fill" : "circle"
        checkboxButton.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)
    }

    func setUp(imageURL: String, name: String?) {
        imageView.setImage(with: imageURL)
        titleLabel.text = name
    }

    func setUp(imageURL: String, name: String?, isChecked: Bool) {
        imageView.setImage(with: imageURL)
        titleLabel.text = name
        isVariantChecked = isChecked
    }
}

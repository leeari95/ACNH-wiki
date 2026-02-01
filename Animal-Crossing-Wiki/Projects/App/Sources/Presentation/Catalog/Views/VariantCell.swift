//
//  VariantCell.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/14.
//

import UIKit
import RxSwift
import RxRelay

final class VariantCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!

    var disposeBag = DisposeBag()
    private let checkboxTapped = PublishRelay<Bool>()
    private var isCollected: Bool = false

    private lazy var checkButton: UIButton = {
        let button = UIButton()
        let font = UIFont.preferredFont(forTextStyle: .title2)
        let config = UIImage.SymbolConfiguration(font: font)
        button.setImage(UIImage(systemName: "checkmark.seal", withConfiguration: config), for: .normal)
        button.tintColor = .acNavigationBarTint
        button.backgroundColor = .acSecondaryBackground
        button.layer.cornerRadius = font.pointSize / 2
        button.addTarget(self, action: #selector(checkButtonTapped), for: .touchUpInside)
        return button
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        configure()
        titleLabel.font = .preferredFont(for: .footnote, weight: .bold)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        titleLabel.text = nil
        isCollected = false
        checkButton.isHidden = false
        updateCheckboxImage()
        disposeBag = DisposeBag()
    }

    private func configure() {
        addSubviews(checkButton)
        NSLayoutConstraint.activate([
            checkButton.topAnchor.constraint(equalTo: topAnchor),
            checkButton.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    @objc private func checkButtonTapped() {
        isCollected.toggle()
        updateCheckboxImage()
        checkboxTapped.accept(isCollected)
    }

    private func updateCheckboxImage() {
        let config = UIImage.SymbolConfiguration(font: .preferredFont(forTextStyle: .title2))
        let imageName = isCollected ? "checkmark.seal.fill" : "checkmark.seal"
        checkButton.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)
    }

    func setUp(imageURL: String, name: String?, isCollected: Bool, showCheckbox: Bool) {
        imageView.setImage(with: imageURL)
        titleLabel.text = name
        self.isCollected = isCollected
        checkButton.isHidden = !showCheckbox
        updateCheckboxImage()
    }

    var checkboxObservable: Observable<Bool> {
        return checkboxTapped.asObservable()
    }
}

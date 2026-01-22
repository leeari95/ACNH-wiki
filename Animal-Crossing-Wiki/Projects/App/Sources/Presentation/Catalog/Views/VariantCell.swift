//
//  VariantCell.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/14.
//

import UIKit
import RxSwift

final class VariantCell: UICollectionViewCell {

    private var disposeBag = DisposeBag()

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!

    private lazy var checkButton: UIButton = {
        let button = UIButton()
        let font = UIFont.preferredFont(forTextStyle: .title2)
        let config = UIImage.SymbolConfiguration(font: font)
        button.setImage(UIImage(systemName: "checkmark.seal", withConfiguration: config), for: .normal)
        button.tintColor = .acNavigationBarTint
        button.backgroundColor = .acSecondaryBackground
        button.layer.cornerRadius = font.pointSize / 2
        return button
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.font = .preferredFont(for: .footnote, weight: .bold)
        addSubviews(checkButton)
        NSLayoutConstraint.activate([
            checkButton.topAnchor.constraint(equalTo: imageView.topAnchor),
            checkButton.trailingAnchor.constraint(equalTo: imageView.trailingAnchor)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        titleLabel.text = nil
        disposeBag = DisposeBag()
        checkButton.setImage(
            UIImage(
                systemName: "checkmark.seal",
                withConfiguration: UIImage.SymbolConfiguration(font: .preferredFont(forTextStyle: .title2))
            ),
            for: .normal
        )
    }

    func setUp(imageURL: String, name: String?, item: Variant, checkButtonTapObserver: AnyObserver<Variant>?) {
        imageView.setImage(with: imageURL)
        titleLabel.text = name
        
        if let checkButtonTapObserver {
            checkButton.rx.tap
                .map { _ in item }
                .bind(to: checkButtonTapObserver)
                .disposed(by: disposeBag)
        }
    }
}

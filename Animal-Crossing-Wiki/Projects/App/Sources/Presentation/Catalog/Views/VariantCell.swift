//
//  VariantCell.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/14.
//

import UIKit
import RxSwift

final class VariantCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    private lazy var checkButton: UIButton = {
        let button = UIButton()
        let font = UIFont.preferredFont(forTextStyle: .body)
        let config = UIImage.SymbolConfiguration(font: font)
        button.setImage(UIImage(systemName: "checkmark.circle", withConfiguration: config), for: .normal)
        button.setImage(UIImage(systemName: "checkmark.circle.fill", withConfiguration: config), for: .selected)
        button.tintColor = .acNavigationBarTint
        button.backgroundColor = .acSecondaryBackground
        button.layer.cornerRadius = font.pointSize / 2
        return button
    }()
    
    private var disposeBag = DisposeBag()
    private var checkButtonTapped: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.font = .preferredFont(for: .footnote, weight: .bold)
        configure()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        titleLabel.text = nil
        checkButton.isSelected = false
        disposeBag = DisposeBag()
        checkButtonTapped = nil
    }
    
    private func configure() {
        addSubviews(checkButton)
        NSLayoutConstraint.activate([
            checkButton.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            checkButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            checkButton.widthAnchor.constraint(equalToConstant: 24),
            checkButton.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        checkButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.checkButtonTapped?()
            }).disposed(by: disposeBag)
    }

    func setUp(imageURL: String, name: String?, isChecked: Bool = false, onCheckTapped: @escaping () -> Void) {
        imageView.setImage(with: imageURL)
        titleLabel.text = name
        checkButton.isSelected = isChecked
        checkButtonTapped = onCheckTapped
    }
}

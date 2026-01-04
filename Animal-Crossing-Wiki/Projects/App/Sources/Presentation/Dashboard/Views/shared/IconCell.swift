//
//  ItemRow.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/20.
//

import UIKit

final class IconCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        removeCheckMark()
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

    func removeCheckMark() {
        let checkImage = imageView.subviews.last as? UIImageView
        checkImage?.removeFromSuperview()
    }

    func setChecked(_ isChecked: Bool) {
        removeCheckMark()
        guard isChecked else {
            return
        }
        let checkImage = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        checkImage.tintColor = .acHeaderBackground
        checkImage.backgroundColor = .white
        checkImage.layer.cornerRadius = 10
        imageView.addSubviews(checkImage)

        NSLayoutConstraint.activate([
            checkImage.topAnchor.constraint(equalTo: imageView.topAnchor),
            checkImage.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            checkImage.widthAnchor.constraint(equalToConstant: 20),
            checkImage.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    func checkMark() {
        setChecked(true)
    }
}

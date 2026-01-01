//
//  ItemRow.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/20.
//

import UIKit

final class IconCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!

    private var itemName: String?
    private var isItemChecked: Bool = false

    override func awakeFromNib() {
        super.awakeFromNib()
        setupAccessibility()
    }

    private func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        removeCheckMark()
        itemName = nil
        isItemChecked = false
        updateAccessibilityLabel()
    }

    private func updateAccessibilityLabel() {
        if let name = itemName {
            let checkedStatus = isItemChecked ? "checked".localized : "unchecked".localized
            accessibilityLabel = "\(name), \(checkedStatus)"
            accessibilityHint = "double_tap_to_toggle_check".localized
        } else {
            accessibilityLabel = nil
            accessibilityHint = nil
        }
    }

    func setAccessibilityInfo(name: String, isChecked: Bool) {
        self.itemName = name
        self.isItemChecked = isChecked
        updateAccessibilityLabel()
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
        let wasChecked = imageView.alpha == 1
        self.imageView.alpha = wasChecked ? 0.5 : 1
        isItemChecked = !wasChecked
        updateAccessibilityLabel()

        // 토글 시 접근성 알림
        let announcement = isItemChecked ? "item_checked".localized : "item_unchecked".localized
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }

    func removeCheckMark() {
        let checkImage = imageView.subviews.last as? UIImageView
        checkImage?.removeFromSuperview()
    }

    func setChecked(_ isChecked: Bool, announceChange: Bool = false) {
        let previousState = isItemChecked
        isItemChecked = isChecked
        removeCheckMark()
        updateAccessibilityLabel()

        // 체크 상태 변경 시 접근성 알림
        if announceChange && previousState != isChecked {
            let announcement = isChecked ? "item_checked".localized : "item_unchecked".localized
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }

        guard isChecked else { return }
        let checkImage = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        checkImage.tintColor = .acHeaderBackground
        checkImage.backgroundColor = .white
        checkImage.layer.cornerRadius = 10
        checkImage.isAccessibilityElement = false
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

//
//  VillagerHouseView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/04.
//

import UIKit

class VillagerHouseView: UIView {

    private lazy var houseImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    private func configure() {
        addSubviews(houseImageView)

        let height = houseImageView.heightAnchor.constraint(equalToConstant: 300)
        height.priority = .required
        NSLayoutConstraint.activate([
            houseImageView.widthAnchor.constraint(equalToConstant: 300),
            height,
            houseImageView.topAnchor.constraint(equalTo: topAnchor, constant: -40),
            houseImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            houseImageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

extension VillagerHouseView {
    convenience init(_ houseImage: String) {
        self.init(frame: .zero)
        houseImageView.setImage(with: houseImage)
        configure()
    }
}

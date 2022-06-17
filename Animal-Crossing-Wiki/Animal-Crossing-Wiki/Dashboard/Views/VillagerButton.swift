//
//  VillagerButton.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/15.
//

import UIKit

class VillagerButton: UIButton {
    
    private var villager: Villager?

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    private func configure() {
        widthAnchor.constraint(equalToConstant: 40).isActive = true
        heightAnchor.constraint(equalTo: widthAnchor).isActive = true
        alpha = 1
        addTarget(self, action: #selector(tappedButton(_:)), for: .touchUpInside)
    }
    
    @objc private func tappedButton(_ sender: UIButton) {
        alpha = alpha == 0.5 ? 1 : 0.5
        debugPrint(villager)
    }

}

extension VillagerButton {
    convenience init(_ vilager: Villager) {
        self.init(frame: .zero)
        setImage(with: vilager.iconImage)
        self.villager = vilager
    }
}

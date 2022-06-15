//
//  VillagersStackView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/15.
//

import UIKit

class VillagersStackView: UIStackView {

    var isFull: Bool {
        return subviews.count >= 5
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    private func configure() {
        axis = .horizontal
        alignment = .fill
        distribution = .fill
        spacing = 32
    }
    
    func addButton(_ view: UIView) {
        guard isFull == false else {
            return
        }
        addArrangedSubviews(view)
    }

}

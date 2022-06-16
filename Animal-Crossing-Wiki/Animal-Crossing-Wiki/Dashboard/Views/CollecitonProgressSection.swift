//
//  CollecitonProgressSection.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/15.
//

import UIKit

class CollecitonProgressSection: UIView {

    private lazy var backgroundStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .equalCentering
        stackView.spacing = 0
        return stackView
    }()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    private func configure() {
        addSubviews(backgroundStackView)
        
        let heightAnchor = backgroundStackView.heightAnchor.constraint(equalTo: heightAnchor)
        heightAnchor.priority = .defaultHigh
        NSLayoutConstraint.activate([
            backgroundStackView.topAnchor.constraint(equalTo: topAnchor),
            backgroundStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundStackView.widthAnchor.constraint(equalTo: widthAnchor),
            heightAnchor
        ])
        
        let defaultCollection = [
            ("Fish6", 80),
            ("Ins1", 80),
            ("div11", 40),
            ("Inv60", 73),
            ("icon-board", 43)
        ]
        
        backgroundStackView.addArrangedSubviews(
            defaultCollection.map {
                ProgressView(
                    icon: $0.0,
                    progress: Int.random(in: 1...Int($0.1)),
                    maxCount: $0.1)
            }
        )
    }

}

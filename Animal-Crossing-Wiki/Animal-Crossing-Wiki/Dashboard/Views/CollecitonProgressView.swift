//
//  CollecitonProgressView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/15.
//

import UIKit
import RxSwift

class CollecitonProgressView: UIView {
    
    private let disposeBag = DisposeBag()

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
        backgroundStackView.addArrangedSubviews(Category.progress().map { ProgressView(category: $0) })
        
        let heightAnchor = backgroundStackView.heightAnchor.constraint(equalTo: heightAnchor)
        heightAnchor.priority = .defaultHigh
        NSLayoutConstraint.activate([
            backgroundStackView.topAnchor.constraint(equalTo: topAnchor),
            backgroundStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundStackView.widthAnchor.constraint(equalTo: widthAnchor),
            heightAnchor
        ])
    }

}

//
//  SectionView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/14.
//

import UIKit

class SectionView: UIView {

    private lazy var headerView: SectionHeaderView = {
        let headerView = SectionHeaderView()
        return headerView
    }()
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .acSecondaryBackground
        view.layer.cornerRadius = 14
        return view
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .acSecondaryBackground
        return view
    }()

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
}

extension SectionView {
    convenience init(title: String, iconName: String, contentView: UIView) {
        self.init(frame: .zero)
        headerView.setUp(title: title, iconName: iconName)
        setUpContent(contentView)
    }
    
    private func configure() {
        addSubviews(headerView, containerView)
        
        let height = heightAnchor.constraint(equalToConstant: 80)
        height.priority = .defaultLow
        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            headerView.topAnchor.constraint(equalTo: topAnchor, constant: 15),
            headerView.heightAnchor.constraint(equalToConstant: 30),
            height
        ])
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
    }
    
    private func setUpContent(_ view: UIView) {
        contentView = view
        
        containerView.addSubviews(contentView)
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 14),
            contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14)
        ])
    }
}

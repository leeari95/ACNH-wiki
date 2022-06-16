//
//  UserInfoSection.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/14.
//

import UIKit

class UserInfoSection: UIView {
    
    var userInfo: UserInfo?
    
    private lazy var backgroundStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 8
        return stackView
    }()
    
    private lazy var userNameView: InfoStackView = {
        let stackView = InfoStackView(
            title: "User Name",
            description: userInfo?.name ?? "Please set a name."
        )
        return stackView
    }()
    
    private lazy var fruitInfoView: InfoStackView = {
        let stackView = InfoStackView(
            title: "Starting Fruit",
            description: userInfo?.islandFruit.rawValue ?? "Please set a Fruit."
        )
        return stackView
    }()
    
    private lazy var islandNameView: InfoStackView = {
        let stackView = InfoStackView(
            title: "Island Name",
            description: userInfo?.islandName ?? "Please set a Island Name."
        )
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
        backgroundStackView.addArrangedSubviews(userNameView, fruitInfoView, islandNameView)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 67),
            backgroundStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            backgroundStackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}

extension UserInfoSection {

    func updateInfo(_ userInfo: UserInfo?) {
        userNameView.editDescription(userInfo?.name)
        fruitInfoView.editDescription(userInfo?.islandFruit.imageName)
        islandNameView.editDescription(userInfo?.islandName)
    }
}

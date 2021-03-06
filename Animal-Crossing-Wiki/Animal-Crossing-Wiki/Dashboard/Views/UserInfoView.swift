//
//  UserInfoSection.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/14.
//

import UIKit
import RxSwift
import RxCocoa

class UserInfoView: UIView {
    
    private let disposeBag = DisposeBag()
    
    private lazy var backgroundStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 4
        return stackView
    }()
    
    private lazy var userNameLabel: UILabel = {
        let label = UILabel()
        label.text = "Please set a name.".localized
        return label
    }()
    
    private lazy var fruitImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: Fruit.apple.imageName)
        return imageView
    }()
    
    private lazy var islandNameLabel: UILabel = {
        let label = UILabel()
        label.text = "Please set a Island Name.".localized
        return label
    }()
    
    private lazy var hemisphereLabel: UILabel = {
        let label = UILabel()
        label.text = Hemisphere.north.rawValue.localized
        return label
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
        backgroundStackView.addArrangedSubviews(
            InfoContentView(title: "ISLAND".localized, contentView: islandNameLabel),
            InfoContentView(title: "USER".localized, contentView: userNameLabel),
            InfoContentView(title: "HEMISPHERE".localized, contentView: hemisphereLabel),
            InfoContentView(title: "FRUIT".localized, contentView: fruitImageView)
            
        )
        
        [islandNameLabel, userNameLabel, hemisphereLabel].forEach { label in
            label.textColor = .acSecondaryText
            label.font = .preferredFont(forTextStyle: .footnote)
            label.textAlignment = .right
            label.heightAnchor.constraint(equalTo: fruitImageView.heightAnchor).isActive = true
        }
        
        NSLayoutConstraint.activate([
            backgroundStackView.topAnchor.constraint(equalTo: topAnchor),
            backgroundStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundStackView.widthAnchor.constraint(equalTo: widthAnchor),
            backgroundStackView.heightAnchor.constraint(equalTo: heightAnchor),
            fruitImageView.widthAnchor.constraint(equalToConstant: 30),
            fruitImageView.heightAnchor.constraint(equalTo: fruitImageView.widthAnchor)
        ])
    }
    
    private func bind(to viewModel: UserInfoSectionViewModel) {
        let output = viewModel.transform(disposeBag: disposeBag)
        output.userInfo
            .compactMap { $0 }
            .withUnretained(self)
            .observe(on: MainScheduler.instance)
            .bind { (owner, userInfo) in
                owner.updateInfo(userInfo)
        }.disposed(by: disposeBag)
    }
    
    private func updateInfo(_ userInfo: UserInfo) {
        guard userInfo != UserInfo() else {
            userNameLabel.text = "Please set a name.".localized
            islandNameLabel.text = "Please set a Island Name.".localized
            return
        }
        userNameLabel.text = userInfo.name == "" ? "Please set a name.".localized : userInfo.name
        islandNameLabel.text = userInfo.islandName  == "" ? "Please set a Island Name.".localized : userInfo.islandName
        fruitImageView.image = UIImage(named: userInfo.islandFruit.imageName)
        hemisphereLabel.text = userInfo.hemisphere.rawValue.localized.capitalized
    }
}

extension UserInfoView {
    convenience init(_ viewModel: UserInfoSectionViewModel) {
        self.init(frame: .zero)
        bind(to: viewModel)
    }
}

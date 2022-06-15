//
//  VillagersSection.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/15.
//

import UIKit
import RxSwift

class VillagersSection: UIView {
    
    private lazy var backgroundStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 20
        return stackView
    }()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    let disposeBag = DisposeBag()
    
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
        Items.shared.villagerList.subscribe(onNext: { villagers in
            let villagers = villagers.filter {
                $0.translations.kRko == "젤리" || $0.translations.kRko == "애플"
                || $0.translations.kRko == "존" || $0.translations.kRko == "리처드"
                || $0.translations.kRko == "병태" || $0.translations.kRko == "잭슨"
                || $0.translations.kRko == "미애" || $0.translations.kRko == "스피카"
                || $0.translations.kRko == "타마" || $0.translations.kRko == "미첼"
            }
            villagers.forEach { villager in
                self.addTask(VillagerButton(villager))
            }
            
        }).disposed(by: disposeBag)
    }
    
    private func addVillagersStackView() {
        backgroundStackView.addArrangedSubviews(VillagersStackView())
    }
    
    func addTask(_ view: UIView) {
        if backgroundStackView.subviews.isEmpty {
            addVillagersStackView()
        }
        var currentVillagersView = backgroundStackView.subviews.last as? VillagersStackView
        if currentVillagersView?.isFull == true {
            addVillagersStackView()
            currentVillagersView = backgroundStackView.subviews.last as? VillagersStackView
            currentVillagersView?.addButton(view)
        } else {
            currentVillagersView?.addButton(view)
        }
    }
}

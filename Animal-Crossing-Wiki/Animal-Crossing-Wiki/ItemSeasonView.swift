//
//  ItemSeasonView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/07.
//

import UIKit
import RxSwift

class ItemSeasonView: UIView {
    
    private let disposeBag = DisposeBag()
    
    private lazy var backgroundStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 8
        return stackView
    }()
    
    private lazy var timeLabel = UILabel(text: "", font: .preferredFont(forTextStyle: .body), color: .acSecondaryText)
    
    private lazy var timeInfoView: UIStackView = {
        let stackView = UIStackView(axis: .horizontal, alignment: .fill, distribution: .fill, spacing: 4)
        let iconImageView = UIImageView(image: UIImage(systemName: "clock.fill"))
        iconImageView.tintColor = .acSecondaryText
        stackView.addArrangedSubviews(iconImageView, timeLabel)
        return stackView
    }()
    
    convenience init(item: Item) {
        self.init(frame: .zero)
        configure(in: item)
    }
    
    private func configure(in item: Item) {
        addSubviews(backgroundStackView)
        backgroundStackView.addArrangedSubviews(timeInfoView)
        
        Items.shared.userInfo
            .compactMap { $0?.hemisphere }
            .withUnretained(self)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { owner, hemisphere in
                switch hemisphere {
                case .south:
                    owner.setUpTime(times: item.hemispheres.south.time)
                    owner.setUpCalendar(months: item.hemispheres.south.monthsArray)
                case .north:
                    owner.setUpTime(times: item.hemispheres.north.time)
                    owner.setUpCalendar(months: item.hemispheres.north.monthsArray)
                }
            }).disposed(by: disposeBag)
        
        NSLayoutConstraint.activate([
            backgroundStackView.topAnchor.constraint(equalTo: topAnchor),
            backgroundStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundStackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    private func setUpTime(times: [String]) {
        if times.count == 1 {
            timeLabel.text = times.first
        } else {
            timeLabel.text = times.reduce("") { $0 + $1 + " / " }.trimmingCharacters(in: ["/", " "])
        }
    }
    
    private func setUpCalendar(months: [Int]) {
        if backgroundStackView.arrangedSubviews.last as? CalendarView != nil {
            backgroundStackView.arrangedSubviews.last?.removeFromSuperview()
        }
        let calendarView = CalendarView(months: months)
        backgroundStackView.addArrangedSubviews(calendarView)
    }
}

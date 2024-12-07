//
//  CalendarView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/07.
//

import UIKit

final class CalendarView: UIView {

    private let months = [
        [
            Calendar.current.shortMonthSymbols[0],
            Calendar.current.shortMonthSymbols[1],
            Calendar.current.shortMonthSymbols[2],
            Calendar.current.shortMonthSymbols[3]
        ],
        [
            Calendar.current.shortMonthSymbols[4],
            Calendar.current.shortMonthSymbols[5],
            Calendar.current.shortMonthSymbols[6],
            Calendar.current.shortMonthSymbols[7]
        ],
        [
            Calendar.current.shortMonthSymbols[8],
            Calendar.current.shortMonthSymbols[9],
            Calendar.current.shortMonthSymbols[10],
            Calendar.current.shortMonthSymbols[11]
        ]
    ]

    private var flatMonths: [String] {
        months.flatMap { $0 }
    }

    private var currentMonth: Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM"
        return Int(formatter.string(from: Date())) ?? 1
    }

    private lazy var backgroundStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 8
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
        return stackView
    }()

    convenience init(months: [Int]) {
        self.init(frame: .zero)
        configure(in: months)
    }

    private func configure(in months: [Int]) {
        layer.cornerRadius = 30
        backgroundColor = .catalogBackground
        addSubviews(backgroundStackView)

        NSLayoutConstraint.activate([
            backgroundStackView.topAnchor.constraint(equalTo: topAnchor),
            backgroundStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundStackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        let stackViews = self.months.map { row -> UIStackView in
            let stackView = UIStackView(axis: .horizontal, alignment: .center, distribution: .fill, spacing: 8)
            let monthViews = row.map { month -> UIView in
                let isActive = months.contains((flatMonths.firstIndex(of: month) ?? 1) + 1)
                let monthView = crateMonthView(month: month, selected: isActive)
                return monthView
            }
            stackView.addArrangedSubviews(monthViews)
            monthViews.forEach { monthView in
                monthView.widthAnchor.constraint(equalToConstant: 50).isActive = true
                monthView.heightAnchor.constraint(equalToConstant: 30).isActive = true
            }
            return stackView
        }
        backgroundStackView.addArrangedSubviews(stackViews)
    }

    private func crateMonthView(month: String, selected: Bool) -> UIView {
        let isCurrentMonth = flatMonths.firstIndex(of: month) == currentMonth - 1
        let monthLabel = UILabel(
            text: month,
            font: .preferredFont(for: .callout, weight: selected ? .bold : .medium),
            color: selected ? .black : .black
        )
        let backgroundView = UIView()
        backgroundView.backgroundColor = selected ? .catalogSelected : .catalogBar
        backgroundView.layer.cornerRadius = 10
        backgroundView.layer.borderWidth = 3
        backgroundView.layer.borderColor = isCurrentMonth ? UIColor.acTabBarTint.cgColor : UIColor.clear.cgColor
        backgroundView.addSubviews(monthLabel)
        monthLabel.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor).isActive = true
        monthLabel.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor).isActive = true
        return backgroundView
    }
}

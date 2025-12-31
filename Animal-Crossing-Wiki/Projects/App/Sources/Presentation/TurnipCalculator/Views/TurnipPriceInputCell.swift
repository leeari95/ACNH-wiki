//
//  TurnipPriceInputCell.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import UIKit
import RxSwift

final class TurnipPriceInputCell: UITableViewCell {

    static let reuseIdentifier = "TurnipPriceInputCell"

    var disposeBag = DisposeBag()

    private lazy var dayLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(for: .body, weight: .medium)
        label.textColor = .acText
        return label
    }()

    private lazy var priceTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.keyboardType = .numberPad
        textField.placeholder = "0"
        textField.textAlignment = .right
        textField.font = .preferredFont(for: .body, weight: .regular)
        textField.backgroundColor = .acSecondaryBackground
        return textField
    }()

    private lazy var bellsLabel: UILabel = {
        let label = UILabel()
        label.text = "Bells".localized
        label.font = .preferredFont(for: .footnote, weight: .regular)
        label.textColor = .acSecondaryText
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        priceTextField.text = nil
        dayLabel.text = nil
    }

    private func setUpViews() {
        selectionStyle = .none
        backgroundColor = .acBackground

        let inputStack = UIStackView(arrangedSubviews: [priceTextField, bellsLabel])
        inputStack.axis = .horizontal
        inputStack.spacing = 8
        inputStack.alignment = .center

        let mainStack = UIStackView(arrangedSubviews: [dayLabel, inputStack])
        mainStack.axis = .horizontal
        mainStack.distribution = .equalSpacing
        mainStack.alignment = .center

        contentView.addSubviews(mainStack)

        NSLayoutConstraint.activate([
            priceTextField.widthAnchor.constraint(equalToConstant: 100),
            priceTextField.heightAnchor.constraint(equalToConstant: 36),

            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    func configure(dayLabel: String, price: Int?, index: Int, onPriceChanged: @escaping (Int, String?) -> Void) {
        self.dayLabel.text = dayLabel.localized

        if let price = price {
            priceTextField.text = "\(price)"
        } else {
            priceTextField.text = nil
        }

        priceTextField.rx.controlEvent(.editingDidEnd)
            .withLatestFrom(priceTextField.rx.text)
            .subscribe(onNext: { text in
                onPriceChanged(index, text)
            })
            .disposed(by: disposeBag)
    }
}

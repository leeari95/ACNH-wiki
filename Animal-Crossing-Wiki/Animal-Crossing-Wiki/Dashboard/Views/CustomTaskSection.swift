//
//  EditTaskSection.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/20.
//

import UIKit
import RxSwift

class CustomTaskSection: UIView {
    
    private lazy var backgroundStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        stackView.spacing = 10
        return stackView
    }()
    
    private lazy var taskNameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Name of the task"
        textField.tintColor = .acText
        textField.textColor = .acText.withAlphaComponent(0.8)
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.font = .preferredFont(forTextStyle: .footnote)
        textField.textAlignment = .right
        textField.delegate = self
        return textField
    }()
    
    private lazy var maxAmountButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("1", for: .normal)
        return button
    }()

    private lazy var iconButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(named: "Inv7")?
            .resizedImage(Size: CGSize(width: 30, height: 30))?
            .withRenderingMode(.alwaysOriginal)
        button.setImage(image, for: .normal)
        return button
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
        NSLayoutConstraint.activate([
            backgroundStackView.topAnchor.constraint(equalTo: topAnchor),
            backgroundStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundStackView.widthAnchor.constraint(equalTo: widthAnchor),
            backgroundStackView.heightAnchor.constraint(equalTo: heightAnchor),
            taskNameTextField.heightAnchor.constraint(equalToConstant: maxAmountButton.intrinsicContentSize.height)
        ])
        
        [maxAmountButton, iconButton].forEach {
            $0.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
            $0.contentHorizontalAlignment = .right
            $0.setTitleColor(.acText.withAlphaComponent(0.8), for: .normal)
        }
        
        backgroundStackView.addArrangedSubviews(
            InfoContentView(title: "Task Name", contentView: taskNameTextField),
            InfoContentView(title: "Icon", contentView: iconButton),
            InfoContentView(title: "Max amount", contentView: maxAmountButton)
        )
    }
}
extension CustomTaskSection {
    
    var taskNameObservable: Observable<String?> {
        taskNameTextField.rx.text.asObservable()
    }
    
    var iconButtonObservable: Observable<Void> {
        iconButton.rx.tap.asObservable()
    }
    
    var maxAmountButtonObservable: Observable<Void> {
        maxAmountButton.rx.tap.asObservable()
    }
    
    func setUpViews(_ task: DailyTask) {
        taskNameTextField.text = task.name
        updateIcon(task.icon)
        updateAmount(task.amount.description)
    }

    func updateAmount(_ amount: String) {
        maxAmountButton.setTitle(amount, for: .normal)
    }
    
    func updateIcon(_ icon: String) {
        let image = UIImage(named: icon)?
            .resizedImage(Size: CGSize(width: 30, height: 30))?
            .withRenderingMode(.alwaysOriginal)
        iconButton.setImage(image, for: .normal)
    }
}

extension CustomTaskSection: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
    }

}

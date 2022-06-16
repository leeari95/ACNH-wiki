//
//  TodaysTasksSesction.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/15.
//

import UIKit

class TodaysTasksSesction: UIView {

    private lazy var backgroundStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 10
        return stackView
    }()
    
    private lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 50
        
        let editButton = UIButton(type: .system)
        editButton.setTitle("Edit", for: .normal)
        
        let resetButton = UIButton(type: .system)
        resetButton.setTitle("Reset", for: .normal)
        
        stackView.addArrangedSubviews(editButton, resetButton)
        
        stackView.arrangedSubviews.forEach { view in
            let button = view as? UIButton
            button?.setTitleColor(.acText, for: .normal)
            button?.titleLabel?.font = .preferredFont(for: .footnote, weight: .bold)
            button?.backgroundColor = .acText.withAlphaComponent(0.2)
            button?.layer.cornerRadius = 12
            button?.widthAnchor.constraint(equalToConstant: 56).isActive = true
            button?.heightAnchor.constraint(equalToConstant: 28).isActive = true
        }
                
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
        addSubviews(backgroundStackView, buttonStackView)
        
        let heightAnchor = backgroundStackView.heightAnchor.constraint(equalTo: heightAnchor, constant: -40)
        heightAnchor.priority = .defaultHigh
        NSLayoutConstraint.activate([
            buttonStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            buttonStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            backgroundStackView.topAnchor.constraint(equalTo: topAnchor),
            backgroundStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundStackView.widthAnchor.constraint(equalTo: widthAnchor),
            heightAnchor
        ])
        
        let defaultTasks = [
            ("Inv167", 6),
            ("Inv60", 4),
            ("Inv63", 2),
            ("Inv48", 1),
            ("Inv105", 1),
            ("Inv107", 1),
            ("Inv192", 1),
            ("Inv6", 1),
            ("Inv199", 1)
        ]
        defaultTasks.forEach { (icon, count) in
            (0..<count).forEach { _ in
                addTask(TaskButton(iconName: icon))
            }
        }
    }
    
    private func addTasksStackView() {
        backgroundStackView.addArrangedSubviews(TasksStackView())
    }
    
    func addTask(_ view: UIView) {
        if backgroundStackView.subviews.isEmpty {
            addTasksStackView()
        }
        var currentTasksView = backgroundStackView.subviews.last as? TasksStackView
        if currentTasksView?.isFull == true {
            addTasksStackView()
            currentTasksView = backgroundStackView.subviews.last as? TasksStackView
            currentTasksView?.addButton(view)
        } else {
            currentTasksView?.addButton(view)
        }
    }
}

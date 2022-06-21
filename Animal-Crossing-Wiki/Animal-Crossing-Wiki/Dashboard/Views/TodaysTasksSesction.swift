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
        return stackView
    }()
    
    private lazy var editButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Edit", for: .normal)
        return button
    }()
    
    private lazy var resetButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Reset", for: .normal)
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
        
        [editButton, resetButton].forEach {
            $0.setTitleColor(.acText, for: .normal)
            $0.titleLabel?.font = .preferredFont(for: .footnote, weight: .bold)
            $0.backgroundColor = .acText.withAlphaComponent(0.2)
            $0.layer.cornerRadius = 12
            $0.widthAnchor.constraint(equalToConstant: 56).isActive = true
            $0.heightAnchor.constraint(equalToConstant: 28).isActive = true
        }
        buttonStackView.addArrangedSubviews(editButton, resetButton)
        
        DailyTask.tasks.forEach { task in
            (0..<task.amount).forEach { index in
                addTask(TaskButton(task, index: index))
            }
        }
    }
    
    private func addTasksStackView() {
        backgroundStackView.addArrangedSubviews(TasksStackView())
    }
}

extension TodaysTasksSesction {
    
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
    
    func addTarget(_ viewController: UIViewController, edit: Selector, reset: Selector) {
        editButton.addTarget(viewController, action: edit, for: .touchUpInside)
        resetButton.addTarget(viewController, action: reset, for: .touchUpInside)
    }
    
    func reset() {
        backgroundStackView.arrangedSubviews.forEach { view in
            let tasksStaskView = view as? TasksStackView
            tasksStaskView?.reset()
        }
    }
}

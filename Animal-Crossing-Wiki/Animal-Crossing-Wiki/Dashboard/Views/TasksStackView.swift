//
//  TasksStackView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/15.
//

import UIKit

class TasksStackView: UIStackView {
    
    var isFull: Bool {
        return subviews.count >= 6
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    private func configure() {
        axis = .horizontal
        alignment = .fill
        distribution = .fill
        spacing = 18
    }
    
    func addButton(_ view: UIView) {
        guard isFull == false else {
            return
        }
        addArrangedSubviews(view)
    }
    
    func reset() {
        arrangedSubviews.forEach { view in
            let taskButton = view as? TaskButton
            taskButton?.reset()
        }
    }

}

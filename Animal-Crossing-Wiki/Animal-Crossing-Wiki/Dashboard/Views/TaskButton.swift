//
//  TaskButton.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/15.
//

import UIKit

class TaskButton: UIButton {
    
    private var task: DailyTask?
    private var index: Int = 0

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    private func configure() {
        widthAnchor.constraint(equalToConstant: 40).isActive = true
        heightAnchor.constraint(equalTo: widthAnchor).isActive = true
        alpha = 0.5
        addTarget(self, action: #selector(tappedButton(_:)), for: .touchUpInside)
    }
    
    @objc private func tappedButton(_ sender: UIButton) {
        alpha = alpha == 0.5 ? 1 : 0.5
        task?.toggleCompleted(self.index)
    }
}

extension TaskButton {
    convenience init(_ task: DailyTask, index: Int) {
        self.init(frame: .zero)
        self.task = task
        self.index = index
        let image = UIImage(named: task.icon)?.withRenderingMode(.alwaysOriginal)
        setImage(image, for: .normal)
        alpha = task.progressList[index] ? 1 : 0.5
    }
    
    func reset() {
        self.task?.reset()
        alpha = 0.5
    }
}

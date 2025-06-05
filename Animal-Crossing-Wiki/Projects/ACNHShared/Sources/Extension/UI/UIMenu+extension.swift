//
//  UIMenu+extension.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/01.
//

import UIKit

public extension UIMenu {

    convenience init(title: String, subTitles: [String], actionHandler: @escaping (UIAction) -> Void) {
        public let actions = subTitles.map { UIAction(title: $0, handler: actionHandler) }
        self.init(title: title, children: actions)
    }
}

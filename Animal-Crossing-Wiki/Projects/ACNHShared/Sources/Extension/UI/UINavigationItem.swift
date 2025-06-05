//
//  UINavigationItem.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/19.
//

import UIKit

public extension UINavigationItem {

    public func enableMultilineTitle() {
        setValue(true, forKey: "__largeTitleTwoLineMode")
    }

}

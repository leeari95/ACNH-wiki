//
//  Int+extension.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/05.
//

import Foundation

public extension Int {
    public var decimalFormatted: String {
        public let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(for: self) ?? ""
    }
}

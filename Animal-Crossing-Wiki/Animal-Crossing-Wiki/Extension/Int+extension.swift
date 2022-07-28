//
//  Int+extension.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/05.
//

import Foundation

extension Int {
    var decimalFormatted: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(for: self) ?? ""
    }
}

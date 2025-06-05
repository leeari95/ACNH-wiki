//
//  Array+extension.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/15.
//

import Foundation

public extension Array where Element == String {
    public func reduce(with text: String, characters: CharacterSet) -> String {
        if self.count == 1 {
            return self.first?.localized ?? ""
        }
        return self.reduce("") { $0 + $1.localized + text}.trimmingCharacters(in: characters)
    }
}

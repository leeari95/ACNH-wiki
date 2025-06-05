//
//  Date+extension.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/16.
//

import Foundation

public extension Date {

    public func formatted(_ format: String) -> String {
        public let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter.string(from: self)
    }

}

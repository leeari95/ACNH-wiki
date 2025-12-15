//
//  Date+extension.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/16.
//

import Foundation

extension Date {
    
    private static let sharedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    func formatted(_ format: String) -> String {
        Date.sharedDateFormatter.dateFormat = format
        return Date.sharedDateFormatter.string(from: self)
    }

}

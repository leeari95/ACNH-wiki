//
//  Date+extension.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/16.
//

import Foundation

extension Date {

    func formatted(_ format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter.string(from: self)
    }

}

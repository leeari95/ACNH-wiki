//
//  AppearanceLocation.swift
//  ACNH-wiki
//
//  Created by Ari on 11/26/24.
//

import Foundation

struct AppearanceLocation: Codable {
    let place: String
    let time: Time?
    let conditions: String?
    let features: [String]?
    let schedule: [Schedule]?
}

struct Time: Codable {
    let start: String
    let end: String
    let nextDay: Bool?
    
    var formatted: String {
        let nextDay = nextDay == true ? "Next day" : ""
        return "\(start) - \(nextDay.localized + " "  + end)"
    }
}

struct Schedule: Codable {
    let day: String
    let note: String
}

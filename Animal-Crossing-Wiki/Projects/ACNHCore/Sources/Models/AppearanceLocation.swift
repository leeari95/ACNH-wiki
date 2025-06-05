//
//  AppearanceLocation.swift
//  ACNH-wiki
//
//  Created by Ari on 11/26/24.
//

import Foundation

public struct AppearanceLocation: Codable {
    public let place: String
    public let time: Time?
    public let conditions: String?
    public let features: [String]?
    public let schedule: [Schedule]?
}

public struct Time: Codable {
    public let start: String
    public let end: String
    public let nextDay: Bool?
    
    public var formatted: String {
        public let nextDay = nextDay == true ? "Next day " : ""
        return "\(start) - \(nextDay.localized + end)"
    }
}

public struct Schedule: Codable {
    public let day: String
    public let note: String
}

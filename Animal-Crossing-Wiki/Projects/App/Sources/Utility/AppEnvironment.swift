//
//  AppEnvironment.swift
//  Animal-Crossing-Wiki
//
//  Created by Codex on 2026/06/04.
//

import Foundation

enum AppEnvironment {
    static var isUnitTesting: Bool {
        ProcessInfo.processInfo.environment["IS_UNIT_TESTING"] == "1"
            || NSClassFromString("XCTestCase") != nil
    }
}

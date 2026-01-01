//
//  ErrorHandling.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2025/01/06.
//

import Foundation

protocol ErrorHandling {
    func handleError(_ error: Error, operation: String)
}

extension ErrorHandling {
    func handleError(_ error: Error, operation: String) {
        // 에러 로깅
        print("❌ CoreData Error in \(operation): \(error.localizedDescription)")
        
        // 사용자에게 알림 (NotificationCenter 사용)
        NotificationCenter.default.post(
            name: .coreDataError,
            object: nil,
            userInfo: [
                "operation": operation,
                "error": error.localizedDescription
            ]
        )
    }
}

extension Notification.Name {
    static let coreDataError = Notification.Name("CoreDataError")
}
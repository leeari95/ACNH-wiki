//
//  DailyTask.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/08.
//

import Foundation

struct DailyTask {
    let id: UUID = UUID()
    let icon: String
    private(set) var isCompleted: Bool
    
    mutating func toggleCompleted() {
        self.isCompleted.toggle()
    }
}

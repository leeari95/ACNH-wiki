//
//  DailyTask.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/08.
//

import Foundation

struct DailyTask {
    let id: UUID = UUID()
    let name: String
    let icon: String
    private(set) var progressList: [Bool]
    let amount: Int
    
    mutating func toggleCompleted(_ index: Int) {
        self.progressList[index].toggle()
    }
    
    mutating func reset() {
        self.progressList = Array(repeating: false, count: amount)
    }
}

extension DailyTask {
    
    init() {
        self.name = ""
        self.icon = ""
        self.progressList = Array(repeating: false, count: 1)
        self.amount = 1
    }
    
    init(name: String, icon: String, isCompleted: Bool, amount: Int) {
        self.name = name
        self.icon = icon
        self.progressList = Array(repeating: isCompleted, count: amount)
        self.amount = amount
    }
    
    static var tasks: [DailyTask] {
        return [
            DailyTask(name: "Hit rocks", icon: "Inv167", isCompleted: false, amount: 6),
            DailyTask(name: "Find fossils", icon: "Inv60", isCompleted: false, amount: 4),
            DailyTask(name: "Find furniture", icon: "Inv63", isCompleted: false, amount: 2),
            DailyTask(name: "Obtain DIY from vilager", icon: "Inv48", isCompleted: false, amount: 1),
            DailyTask(name: "Find bottle message", icon: "Inv105", isCompleted: false, amount: 1),
            DailyTask(name: "Find buried bell", icon: "Inv107", isCompleted: false, amount: 1),
            DailyTask(name: "Cut down trees", icon: "Inv192", isCompleted: false, amount: 1),
            DailyTask(name: "Buy music", icon: "Inv6", isCompleted: false, amount: 1),
            DailyTask(name: "Find peral", icon: "Inv199", isCompleted: false, amount: 1)
        ]
    }
}

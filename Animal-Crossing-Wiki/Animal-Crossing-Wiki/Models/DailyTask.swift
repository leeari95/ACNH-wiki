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
    private(set) var isCompleted: Bool
    let amount: Int
    
    mutating func toggleCompleted() {
        self.isCompleted.toggle()
    }
}

extension DailyTask {
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

//
//  DailyTask.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/08.
//

import Foundation

public struct DailyTask {
    public let id: UUID
    public let name: String
    public let icon: String
    private(set) var progressList: [Bool]
    public let amount: Int
    public let createdDate: Date

    mutating func toggleCompleted(_ index: Int) {
        self.progressList[index].toggle()
    }

    mutating func reset() {
        self.progressList = Array(repeating: false, count: amount)
    }
}

public extension DailyTask {

    public init() {
        self.init(
            id: UUID(),
            name: "",
            icon: "",
            progressList: Array(repeating: false, count: 1),
            amount: 1,
            createdDate: Date()
        )
    }

    public init(name: String, icon: String, isCompleted: Bool, amount: Int, createdDate: Date) {
        self.init(
            id: UUID(),
            name: name,
            icon: icon,
            progressList: Array(repeating: isCompleted, count: amount),
            amount: amount,
            createdDate: createdDate
        )
    }

    static var tasks: [DailyTask] {
        return [
            DailyTask(
                name: "Hit rocks",
                icon: "Inv167",
                isCompleted: false,
                amount: 6,
                createdDate: Date(timeIntervalSince1970: 1654009200.0)
            ),
            DailyTask(
                name: "Find fossils",
                icon: "Inv60",
                isCompleted: false,
                amount: 4,
                createdDate: Date(timeIntervalSince1970: 1654095600.0)
            ),
            DailyTask(
                name: "Find furniture",
                icon: "Inv63",
                isCompleted: false,
                amount: 2,
                createdDate: Date(timeIntervalSince1970: 1654182000.0)
            ),
            DailyTask(
                name: "Obtain DIY from vilager",
                icon: "Inv48",
                isCompleted: false,
                amount: 1,
                createdDate: Date(timeIntervalSince1970: 1654268400.0)
            ),
            DailyTask(
                name: "Find bottle message",
                icon: "Inv105",
                isCompleted: false,
                amount: 1,
                createdDate: Date(timeIntervalSince1970: 1654354800.0)
            ),
            DailyTask(
                name: "Find buried bell",
                icon: "Inv107",
                isCompleted: false,
                amount: 1,
                createdDate: Date(timeIntervalSince1970: 1654441200.0)
            ),
            DailyTask(
                name: "Cut down trees",
                icon: "Inv192",
                isCompleted: false,
                amount: 1,
                createdDate: Date(timeIntervalSince1970: 1654527600.0)
            ),
            DailyTask(
                name: "Buy music",
                icon: "Inv6",
                isCompleted: false,
                amount: 1,
                createdDate: Date(timeIntervalSince1970: 1654614000.0)
            ),
            DailyTask(
                name: "Find peral",
                icon: "Inv199",
                isCompleted: false,
                amount: 1,
                createdDate: Date(timeIntervalSince1970: 1654700400.0))
        ]
    }
}

public extension DailyTask: Equatable {}

//
//  DailyTaskEntity+Mapping.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation
import CoreData

extension DailyTaskEntity {

    convenience init(_ task: DailyTask, context: NSManagedObjectContext) {
        self.init(context: context)
        self.id = task.id
        self.name = task.name
        self.icon = task.icon
        self.progressList = task.progressList as NSArray
        self.amount = Int64(task.amount)
        self.date = task.createdDate
    }

    func toDomain() -> DailyTask {
        let amount = Int(self.amount)

        // CloudKit 부분 import/sync reset 후 progressList가 nil이거나 amount보다 짧을 수 있음.
        // UI는 amount 기준으로 체크박스를 만들기 때문에 길이를 amount에 맞춰 정규화해
        // index out of range 크래시를 방지한다.
        var progressList = (self.progressList as? [Bool]) ?? []
        if progressList.count < amount {
            progressList.append(contentsOf: Array(repeating: false, count: amount - progressList.count))
        }

        return DailyTask(
            id: self.id ?? UUID(),
            name: self.name ?? "",
            icon: self.icon ?? "",
            progressList: progressList,
            amount: amount,
            createdDate: self.date ?? Date()
        )
    }
}

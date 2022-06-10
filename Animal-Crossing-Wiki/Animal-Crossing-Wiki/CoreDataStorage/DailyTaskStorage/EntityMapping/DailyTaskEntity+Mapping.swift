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
        self.icon = task.icon
        self.isCompleted = task.isCompleted
    }
    
    func toDomain() -> DailyTask {
        return DailyTask(icon: self.icon ?? "", isCompleted: self.isCompleted)
    }
}

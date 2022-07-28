//
//  DailyTaskStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation
import RxSwift

protocol DailyTaskStorage {
    
    func fetchTasks() -> Single<[DailyTask]>
    func insertTask(_ task: DailyTask) -> Single<DailyTask>
    func updateTask(_ task: DailyTask)
    func toggleCompleted(_ task: DailyTask, progressIndex: Int)
    func deleteTaskDelete(_ task: DailyTask) -> Single<DailyTask>
}

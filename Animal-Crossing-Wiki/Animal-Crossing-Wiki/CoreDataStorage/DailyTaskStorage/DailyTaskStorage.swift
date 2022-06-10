//
//  DailyTaskStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation

protocol DailyTaskStorage {
    func fetchTasks(completion: @escaping (Result<[DailyTask], Error>) -> Void)
    func insertTask(_ task: DailyTask, completion: @escaping (Result<DailyTask, Error>) -> Void)
    func deleteTaskDelete(_ task: DailyTask, completion: @escaping (Result<DailyTask, Error>) -> Void)
}

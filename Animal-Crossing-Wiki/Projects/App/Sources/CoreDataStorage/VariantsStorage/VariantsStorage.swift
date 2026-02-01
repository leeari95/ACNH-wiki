//
//  VariantsStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Claude Code on 2026/02/01.
//

import Foundation
import RxSwift

protocol VariantsStorage {
    func fetch() -> Single<Set<String>>
    func fetchByItem(_ itemName: String) -> Single<Set<String>>
    func fetchAll() -> Single<[String: Set<String>]>
    func add(_ variantId: String, itemName: String)
    func remove(_ variantId: String)
    func removeAll(for itemName: String)
}

//
//  ItemEntityStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation
import RxSwift
import ACNHCore
import ACNHShared

protocol ItemsStorage {

    func fetch() -> Single<[Item]>
    func update(_ item: Item)
    func updates(_ items: [Item])
    func reset(category: Category)
}

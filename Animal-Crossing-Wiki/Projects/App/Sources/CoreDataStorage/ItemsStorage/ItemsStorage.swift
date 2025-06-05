//
//  ItemEntityStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation
import RxSwift

protocol ItemsStorage {

    func fetch() -> Single<[Item]>
    func update(_ item: Item)
    func updates(_ items: [Item])
    func reset(category: Category)
    func updateVariantCheck(item: Item, variantId: String, isChecked: Bool)
}

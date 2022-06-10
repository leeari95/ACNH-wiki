//
//  ItemEntityStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation

protocol ItemsStorage {
    func fetchItem(completion: @escaping (Result<[Item], Error>) -> Void)
    func insertItem(_ item: Item, completion: @escaping (Result<Item, Error>) -> Void)
    func deleteItemDelete(_ item: Item, completion: @escaping (Result<Item, Error>) -> Void)
}

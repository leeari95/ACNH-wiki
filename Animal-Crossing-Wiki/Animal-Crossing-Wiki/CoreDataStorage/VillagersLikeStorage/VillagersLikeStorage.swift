//
//  VillagersLikeStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation

protocol VillagersLikeStorage {
    func fetchVillagerLike(completion: @escaping (Result<[Villager], Error>) -> Void)
    func insertVillagerLike(
        _ villager: Villager,
        completion: @escaping (Result<Villager, Error>) -> Void
    )
    func deleteVilagerLikeDelete(
        _ item: Villager,
        completion: @escaping (Result<Villager?, Error>) -> Void
    )
}

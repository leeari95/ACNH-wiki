//
//  VillagersHouseStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation

protocol VillagersHouseStorage {
    func fetchVillagerHouse(completion: @escaping (Result<[Villager], Error>) -> Void)
    func insertVillagerHouse(
        _ villager: Villager,
        completion: @escaping (Result<Villager, Error>) -> Void
    )
    func deleteVilagerHouseelete(
        _ item: Villager,
        completion: @escaping (Result<Villager?, Error>) -> Void
    )
}

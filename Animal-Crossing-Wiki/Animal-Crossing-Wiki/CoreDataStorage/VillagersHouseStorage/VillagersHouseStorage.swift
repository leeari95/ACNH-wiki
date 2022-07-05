//
//  VillagersHouseStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation
import RxSwift

protocol VillagersHouseStorage {
    func fetch() -> Single<[Villager]>
    func update(_ villager: Villager) 
}

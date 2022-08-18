//
//  VillagersLikeStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation
import RxSwift

protocol VillagersLikeStorage {
    func fetch() -> [Villager]
    func update(_ villager: Villager) 
}

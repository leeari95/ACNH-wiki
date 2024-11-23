//
//  NPCLikeStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation
import RxSwift

protocol NPCLikeStorage {
    func fetch() -> [NPC]
    func update(_ villager: NPC)
}

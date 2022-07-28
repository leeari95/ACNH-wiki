//
//  VillagersCellViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/29.
//

import Foundation
import ReactorKit

final class VillagersCellReactor: Reactor {
    
    enum Action {
        case setLikeState(villagers: [Villager])
        case setHouseState(villagers: [Villager])
        case like
        case home
    }
    
    enum Mutation {
        case updateLike
        case updateHouse
        case setLike(_ isLiked: Bool)
        case setHouse(_ isResident: Bool)
    }
    
    struct State {
        var isLiked: Bool?
        var isResident: Bool?
    }
    
    let initialState: State
    private let villager: Villager
    private let likeStorage: VillagersLikeStorage
    private let houseStorage: VillagersHouseStorage
    
    init(
        state: State = State(),
        villager: Villager,
        likeStorage: VillagersLikeStorage = CoreDataVillagersLikeStorage(),
        houseStorage: VillagersHouseStorage = CoreDataVillagersHouseStorage()
    ) {
        self.initialState = state
        self.villager = villager
        self.likeStorage = likeStorage
        self.houseStorage = houseStorage
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .setLikeState(let villagers):
            return .just(.setLike(villagers.contains(where: { $0.name == self.villager.name })))
            
        case .setHouseState(let villagers):
            return .just(.setHouse(villagers.contains(where: { $0.name == self.villager.name })))
            
        case .like:
            return .just(.updateLike)
            
        case .home:
            return .just(.updateHouse)
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setLike(let isLiked):
            newState.isLiked = isLiked
            
        case .setHouse(let isResident):
            newState.isResident = isResident
            
        case .updateHouse:
            HapticManager.shared.impact(style: .medium)
            Items.shared.updateVillagerHouse(villager)
            houseStorage.update(villager)
            
        case .updateLike:
            HapticManager.shared.impact(style: .medium)
            Items.shared.updateVillagerLike(villager)
            likeStorage.update(villager)
        }
        return newState
    }
}

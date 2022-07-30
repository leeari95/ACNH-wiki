//
//  VillagerDetailViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/04.
//

import Foundation
import ReactorKit

final class VillagerDetailReactor: Reactor {
    
    enum Action {
        case fetch
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
        let villager: Villager
        var isLiked: Bool?
        var isResident: Bool?
    }
    
    let initialState: State
    private let likeStorage: VillagersLikeStorage
    private let houseStorage: VillagersHouseStorage
    private let villager: Villager
    
    init(
        villager: Villager,
        state: State,
        likeStorage: VillagersLikeStorage = CoreDataVillagersLikeStorage(),
        houseStorage: VillagersHouseStorage = CoreDataVillagersHouseStorage()
    ) {
        self.villager = villager
        self.initialState = state
        self.likeStorage = likeStorage
        self.houseStorage = houseStorage
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetch:
            let houseState = Items.shared.villagerHouseList
                .take(1)
                .map { $0.contains(where: { $0.name == self.villager.name })}
                .map { Mutation.setHouse($0) }
            let likeState = Items.shared.villagerLikeList
                .take(1)
                .map { $0.contains(where: { $0.name == self.villager.name })}
                .map { Mutation.setLike($0) }
            return .merge([
                houseState,
                likeState
            ])
            
        case .like:
            HapticManager.shared.impact(style: .medium)
            Items.shared.updateVillagerLike(villager)
            likeStorage.update(villager)
            return .just(.updateLike)
            
        case .home:
            HapticManager.shared.impact(style: .medium)
            Items.shared.updateVillagerHouse(villager)
            houseStorage.update(villager)
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
            newState.isResident = newState.isResident == true ? false : true
            
        case .updateLike:
            newState.isLiked = newState.isLiked == true ? false : true
        }
        return newState
    }
}

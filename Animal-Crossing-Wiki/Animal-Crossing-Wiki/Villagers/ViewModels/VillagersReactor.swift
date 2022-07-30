//
//  VillagersViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/29.
//

import Foundation
import ReactorKit

final class VillagersReactor: Reactor {
    
    enum Action {
        case setVillagers(_ villagers: [Villager])
        case setLikeVillagers(_ villagers: [Villager])
        case setHouseVillagers(_ villagers: [Villager])
        case searchText(_ text: String)
        case selectedScope(_ title: String)
        case selectedMenu(keywords: [VillagersViewController.Menu: String])
        case selectedVillager(indexPath: IndexPath)
    }
    
    enum Mutation {
        case setVillagers(_ villagers: [Villager])
        case setAllVillagers(_ villagers: [Villager])
        case setLikeVillagers(_ villagers: [Villager])
        case setHouseVillagers(_ villagers: [Villager])
        case setScope(_ scope: VillagersViewController.SearchScope)
        case transition(route: VillagersCoordinator.Route)
    }
    
    struct State {
        var villagers: [Villager] = []
        var allVillagers: [Villager] = []
        var likeVillagers: [Villager] = []
        var houseVillagers: [Villager] = []
        var currentScope: VillagersViewController.SearchScope = .all
    }
    
    let initialState: State
    var coordinator: VillagersCoordinator?
    
    private var currentKeywords: [VillagersViewController.Menu: String] = [:]
    private var lastSearchKeyword: String = ""
    
    init(coordinator: VillagersCoordinator, state: State = State()) {
        self.coordinator = coordinator
        self.initialState = state
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .setVillagers(let villagers):
            return Observable.just(Mutation.setAllVillagers(villagers))
            
        case .setLikeVillagers(let villagers):
            return Observable.just(Mutation.setLikeVillagers(villagers))
            
        case .setHouseVillagers(let villagers):
            return Observable.just(Mutation.setHouseVillagers(villagers))
            
        case .searchText(let text):
            lastSearchKeyword = text.lowercased()
            guard text != "" else {
                return currentVillagers()
                    .map { self.filtered(villagers: $0, keywords: self.currentKeywords) }
                    .map { Mutation.setVillagers($0) }
            }
            return currentVillagers()
                .map { self.search(villagers: $0, text: text.lowercased()) }
                .map { self.filtered(villagers: $0, keywords: self.currentKeywords) }
                .map { Mutation.setVillagers($0)}
            
        case .selectedScope(let title):
            guard let currentScope = VillagersViewController.SearchScope.transform(title)
                .flatMap({ VillagersViewController.SearchScope(rawValue: $0) }) else {
                return Observable.empty()
            }
            return Observable.just(Mutation.setScope(currentScope))
            
        case .selectedMenu(let keywords):
            currentKeywords = keywords
            return currentVillagers()
                .map { self.filtered(villagers: $0, keywords: keywords) }
                .map { self.search(villagers: $0, text: self.lastSearchKeyword) }
                .map { Mutation.setVillagers($0) }
            
        case .selectedVillager(let indexPath):
            guard let villager = currentState.villagers[safe: indexPath.item] else {
                return Observable.empty()
            }
            return Observable.just(Mutation.transition(route: .detail(villager: villager)))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setVillagers(let villagers):
            newState.villagers = search(villagers: villagers, text: lastSearchKeyword)
            
        case .setAllVillagers(let villagers):
            if currentState.currentScope == .all {
                newState.villagers = villagers
            }
            newState.allVillagers = villagers
            
        case .setLikeVillagers(let villagers):
            if currentState.currentScope == .liked {
                newState.villagers = filtered(
                    villagers: search(villagers: villagers, text: lastSearchKeyword),
                    keywords: self.currentKeywords
                )
                
            }
            newState.likeVillagers = villagers
            
        case .setHouseVillagers(let villagers):
            if currentState.currentScope == .residents {
                newState.villagers = filtered(
                    villagers: search(villagers: villagers, text: lastSearchKeyword),
                    keywords: self.currentKeywords
                )
            }
            newState.houseVillagers = villagers
            
        case .setScope(let scope):
            newState.currentScope = scope
            
        case .transition(let route):
            coordinator?.transition(for: route)
        }
        return newState
    }
    
    private func currentVillagers() -> Observable<[Villager]> {
        switch currentState.currentScope {
        case .all: return .just(currentState.allVillagers)
        case .liked: return .just(currentState.likeVillagers)
        case .residents: return .just(currentState.houseVillagers)
        }
    }
    
    private func filtered(
        villagers: [Villager],
        keywords: [VillagersViewController.Menu: String]
    ) -> [Villager] {
        guard currentKeywords.isEmpty == false else {
            return villagers
        }
        var filteredData = [Villager]()
        currentKeywords = keywords
        keywords
            .sorted { $0.key.rawValue.count > $1.key.rawValue.count }
            .forEach { (key, value) in
            switch key {
            case .personality:
                let value = Personality.transform(localizedString: value) ?? ""
                filteredData = villagers.filter { $0.personality == Personality(rawValue: value) }
                
            case .gender:
                let value = Gender.transform(localizedString: value) ?? ""
                filteredData = (filteredData.isEmpty ? villagers : filteredData)
                    .filter { $0.gender == Gender(rawValue: value)  }
                
            case .type:
                filteredData = (filteredData.isEmpty ? villagers : filteredData)
                    .filter { $0.subtype == Subtype(rawValue: value) }
                
            case .species:
                let value = Specie.transform(localizedString: value) ?? ""
                filteredData = (filteredData.isEmpty ? villagers : filteredData)
                    .filter { $0.species == Specie(rawValue: value) }
                
            case .all: filteredData = villagers
            }
        }
        return filteredData
    }
    
    private func search(villagers: [Villager], text: String) -> [Villager] {
        guard lastSearchKeyword != "" else {
            return villagers
        }
        return villagers
            .filter {
                let villagerName = $0.translations.localizedName()
                let isChosungCheck = text.isChosung
                if isChosungCheck {
                    return (villagerName.contains(text) || villagerName.chosung.contains(text))
                } else {
                    return villagerName.contains(text)
                }
            }
    }
}

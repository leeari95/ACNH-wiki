//
//  VillagersViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/29.
//

import Foundation
import RxSwift
import RxRelay

final class VillagersViewModel {
    enum SearchScope: String {
        case all = "All"
        case liked = "Liked"
        case residents = "Residents"
    }
    
    var coordinator: VillagersCoordinator?
    
    init(coordinator: VillagersCoordinator) {
        self.coordinator = coordinator
    }
    
    struct Input {
        let searchBarText: Observable<String?>
        let seletedScopeButton: Observable<String>
        let didSelectedMenuKeyword: Observable<[String: String]>
    }
    
    struct Output {
        let villagers: Observable<[Villager]>
    }
    
    func transform(input: Input, disposeBag: DisposeBag) -> Output {
        let indicationVillagers = BehaviorRelay<[Villager]>(value: [])
        let currentTap = BehaviorRelay<SearchScope>(value: .all)
        var allVillagers = [Villager]()
        var likeVillagers = [Villager]()
        var houseVillagers = [Villager]()
        
        input.searchBarText
            .compactMap { $0 }
            .subscribe(onNext: { text in
                guard text != "" else {
                    indicationVillagers.accept(allVillagers)
                    switch currentTap.value {
                    case .all:
                        indicationVillagers.accept(allVillagers)
                    case .liked:
                        indicationVillagers.accept(likeVillagers)
                    case .residents:
                        indicationVillagers.accept(houseVillagers)
                    }
                    return
                }
                var filterVillagers = [Villager]()
                switch currentTap.value {
                case .all:
                    filterVillagers = allVillagers
                case .liked:
                    filterVillagers = likeVillagers
                case .residents:
                    filterVillagers = houseVillagers
                }
                filterVillagers = filterVillagers
                    .filter { $0.translations.localizedName().contains(text) }
                indicationVillagers.accept(filterVillagers)
            }).disposed(by: disposeBag)
        
        input.seletedScopeButton
            .compactMap { SearchScope(rawValue: $0) }
            .subscribe(onNext: { selectedScope in
                currentTap.accept(selectedScope)
                switch selectedScope {
                case .all:
                    indicationVillagers.accept(allVillagers)
                case .liked:
                    indicationVillagers.accept(likeVillagers)
                case .residents:
                    indicationVillagers.accept(houseVillagers)
                }
            }).disposed(by: disposeBag)
        
        input.didSelectedMenuKeyword
            .subscribe(onNext: { keywords in
                var filterdVillagers = [Villager]()
                switch currentTap.value {
                case .all:
                    filterdVillagers = allVillagers
                case .liked:
                    filterdVillagers = likeVillagers
                case .residents:
                    filterdVillagers = houseVillagers
                }
                var villagers = [Villager]()
                keywords.sorted { $0.key.count > $1.key.count }.forEach { (key, value) in
                    switch key {
                    case "Personality":
                        let filterdData = filterdVillagers.filter { $0.personality == Personality(rawValue: value) }
                        villagers.append(contentsOf: filterdData)
                    case "Gender":
                        if villagers.isEmpty {
                            let filterdData = filterdVillagers.filter { $0.gender == Gender(rawValue: value) }
                            villagers.append(contentsOf: filterdData)
                        } else {
                            let filterdData = villagers.filter { $0.gender == Gender(rawValue: value) }
                            villagers = filterdData
                        }
                    case "Type":
                        if villagers.isEmpty {
                            let filterdData = filterdVillagers.filter { $0.subtype == Subtype(rawValue: value) }
                            villagers.append(contentsOf: filterdData)
                        } else {
                            let filterdData = villagers.filter { $0.subtype == Subtype(rawValue: value) }
                            villagers = filterdData

                        }
                    case "Species":
                        if villagers.isEmpty {
                            let filterdData = filterdVillagers.filter { $0.species == Specie(rawValue: value) }
                            villagers.append(contentsOf: filterdData)
                        } else {
                            let filterdData = villagers.filter { $0.species == Specie(rawValue: value) }
                            villagers = filterdData

                        }
                    case "All":
                        villagers = filterdVillagers
                    default:
                        return
                    }
                }
                indicationVillagers.accept(villagers)
            }).disposed(by: disposeBag)
        
        Items.shared.villagerList
            .subscribe(onNext: { newVillagers in
                let sortedVillagers = newVillagers
                    .sorted(by: { $0.translations.localizedName() < $1.translations.localizedName() })
                indicationVillagers.accept(sortedVillagers)
                allVillagers = sortedVillagers
            }).disposed(by: disposeBag)
        
        Items.shared.villagerLikeList
            .subscribe(onNext: { villagers in
                let sortedVillagers = villagers
                    .sorted(by: { $0.translations.localizedName() < $1.translations.localizedName() })
                likeVillagers = sortedVillagers
                if currentTap.value == .liked {
                    indicationVillagers.accept(sortedVillagers)
                }
            }).disposed(by: disposeBag)
        
        Items.shared.villagerHouseList
            .subscribe(onNext: { villagers in
                let sortedVillagers = villagers
                    .sorted(by: { $0.translations.localizedName() < $1.translations.localizedName() })
                houseVillagers = sortedVillagers
                if currentTap.value == .residents {
                    indicationVillagers.accept(sortedVillagers)
                }
            }).disposed(by: disposeBag)
        
        return Output(villagers: indicationVillagers.asObservable())
    }
}

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
    
    var coordinator: VillagersCoordinator?
    
    init(coordinator: VillagersCoordinator) {
        self.coordinator = coordinator
    }
    
    struct Input {
        let searchBarText: Observable<String?>
        let seletedScopeButton: Observable<String>
        let didSelectedMenuKeyword: Observable<[VillagersViewController.Menu: String]>
    }
    
    struct Output {
        let villagers: Observable<[Villager]>
    }
    
    func transform(input: Input, disposeBag: DisposeBag) -> Output {
        let indicationVillagers = BehaviorRelay<[Villager]>(value: [])
        let currentTap = BehaviorRelay<VillagersViewController.SearchScope>(value: .all)
        var allVillagers = [Villager]()
        var likeVillagers = [Villager]()
        var houseVillagers = [Villager]()
        
        input.searchBarText
            .compactMap { $0 }
            .subscribe(onNext: { text in
                guard text != "" else {
                    indicationVillagers.accept(allVillagers)
                    switch currentTap.value {
                    case .all: indicationVillagers.accept(allVillagers)
                    case .liked: indicationVillagers.accept(likeVillagers)
                    case .residents: indicationVillagers.accept(houseVillagers)
                    }
                    return
                }
                var filterVillagers = [Villager]()
                switch currentTap.value {
                case .all: filterVillagers = allVillagers
                case .liked: filterVillagers = likeVillagers
                case .residents: filterVillagers = houseVillagers
                }
                filterVillagers = filterVillagers
                    .filter {
                        let villagerName = $0.translations.localizedName()
                        let isChosungCheck = text.isChosung
                        if isChosungCheck {
                            return (villagerName.contains(text) || villagerName.chosung.contains(text))
                        } else {
                            return villagerName.contains(text)
                        }
                    }
                indicationVillagers.accept(filterVillagers)
            }).disposed(by: disposeBag)
        
        input.seletedScopeButton
            .compactMap { VillagersViewController.SearchScope(rawValue: $0) }
            .subscribe(onNext: { selectedScope in
                currentTap.accept(selectedScope)
                switch selectedScope {
                case .all: indicationVillagers.accept(allVillagers)
                case .liked: indicationVillagers.accept(likeVillagers)
                case .residents: indicationVillagers.accept(houseVillagers)
                }
            }).disposed(by: disposeBag)
        
        input.didSelectedMenuKeyword
            .subscribe(onNext: { keywords in
                var filterdVillagers = [Villager]()
                switch currentTap.value {
                case .all: filterdVillagers = allVillagers
                case .liked: filterdVillagers = likeVillagers
                case .residents: filterdVillagers = houseVillagers
                }
                var villagers = [Villager]()
                keywords.sorted { $0.key.rawValue.count > $1.key.rawValue.count }.forEach { (key, value) in
                    switch key {
                    case .personality:
                        let filterdData = filterdVillagers.filter { $0.personality == Personality(rawValue: value) }
                        villagers.append(contentsOf: filterdData)
                    case .gender:
                        if villagers.isEmpty {
                            let filterdData = filterdVillagers.filter { $0.gender == Gender(rawValue: value) }
                            villagers.append(contentsOf: filterdData)
                        } else {
                            let filterdData = villagers.filter { $0.gender == Gender(rawValue: value) }
                            villagers = filterdData
                        }
                    case .type:
                        if villagers.isEmpty {
                            let filterdData = filterdVillagers.filter { $0.subtype == Subtype(rawValue: value) }
                            villagers.append(contentsOf: filterdData)
                        } else {
                            let filterdData = villagers.filter { $0.subtype == Subtype(rawValue: value) }
                            villagers = filterdData

                        }
                    case .species:
                        if villagers.isEmpty {
                            let filterdData = filterdVillagers.filter { $0.species == Specie(rawValue: value) }
                            villagers.append(contentsOf: filterdData)
                        } else {
                            let filterdData = villagers.filter { $0.species == Specie(rawValue: value) }
                            villagers = filterdData
                        }
                    case .all: villagers = filterdVillagers
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

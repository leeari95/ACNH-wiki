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
        let selectedScopeButton: Observable<String>
        let didSelectedMenuKeyword: Observable<[VillagersViewController.Menu: String]>
        let villagerSelected: Observable<IndexPath>
    }
    
    struct Output {
        let villagers: Observable<[Villager]>
        let isLoading: Observable<Bool>
    }
    
    func transform(input: Input, disposeBag: DisposeBag) -> Output {
        let indicationVillagers = BehaviorRelay<[Villager]>(value: [])
        let currentTap = BehaviorRelay<VillagersViewController.SearchScope>(value: .all)
        var allVillagers = [Villager]()
        var likeVillagers = [Villager]()
        var houseVillagers = [Villager]()
        let isLoading = BehaviorRelay<Bool>(value: true)
        
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
        
        input.selectedScopeButton
            .compactMap { VillagersViewController.SearchScope.transform($0) }
            .compactMap { VillagersViewController.SearchScope(rawValue: $0) }
            .subscribe(onNext: { selectedScope in
                currentTap.accept(selectedScope)
            }).disposed(by: disposeBag)
        
        input.didSelectedMenuKeyword
            .subscribe(onNext: { keywords in
                var filteredVillagers = [Villager]()
                switch currentTap.value {
                case .all: filteredVillagers = allVillagers
                case .liked: filteredVillagers = likeVillagers
                case .residents: filteredVillagers = houseVillagers
                }
                var villagers = [Villager]()
                keywords.sorted { $0.key.rawValue.count > $1.key.rawValue.count }.forEach { (key, value) in
                    switch key {
                    case .personality:
                        let value = Personality.transform(localizedString: value) ?? ""
                        let filteredData = filteredVillagers.filter { $0.personality == Personality(rawValue: value) }
                        villagers.append(contentsOf: filteredData)
                    case .gender:
                        let value = Gender.transform(localizedString: value) ?? ""
                        if villagers.isEmpty {
                            let filteredData = filteredVillagers.filter { $0.gender == Gender(rawValue: value) }
                            villagers.append(contentsOf: filteredData)
                        } else {
                            let filteredData = villagers.filter { $0.gender == Gender(rawValue: value) }
                            villagers = filteredData
                        }
                    case .type:
                        if villagers.isEmpty {
                            let filteredData = filteredVillagers.filter { $0.subtype == Subtype(rawValue: value) }
                            villagers.append(contentsOf: filteredData)
                        } else {
                            let filteredData = villagers.filter { $0.subtype == Subtype(rawValue: value) }
                            villagers = filteredData

                        }
                    case .species:
                        let value = Specie.transform(localizedString: value) ?? ""
                        if villagers.isEmpty {
                            let filteredData = filteredVillagers.filter { $0.species == Specie(rawValue: value) }
                            villagers.append(contentsOf: filteredData)
                        } else {
                            let filteredData = villagers.filter { $0.species == Specie(rawValue: value) }
                            villagers = filteredData
                        }
                    case .all: villagers = filteredVillagers
                    }
                }
                indicationVillagers.accept(villagers)
            }).disposed(by: disposeBag)
        
        input.villagerSelected
            .compactMap { indicationVillagers.value[safe: $0.item] }
            .subscribe(onNext: { villager in
                self.coordinator?.transition(for: .detail(villager: villager))
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
        
        Items.shared.isLoading
            .subscribe(onNext: { value in
                isLoading.accept(value)
            }).disposed(by: disposeBag)
        
        return Output(
            villagers: indicationVillagers.asObservable(),
            isLoading: isLoading.asObservable()
        )
    }
}

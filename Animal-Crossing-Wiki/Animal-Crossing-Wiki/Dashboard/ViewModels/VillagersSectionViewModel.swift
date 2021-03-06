//
//  VillagersSectionViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/24.
//

import Foundation
import RxSwift
import RxRelay

final class VillagersSectionViewModel {
    
    private var villagers: [Villager] = []
    private var coordinator: DashboardCoordinator?
    
    init(coordinator: DashboardCoordinator?) {
        self.coordinator = coordinator
    }
    
    struct Input {
        let didSelectItem: Observable<IndexPath>
        let didTapVillagerLongPress: Observable<IndexPath?>
    }
    
    struct Output {
        let villagers: Observable<[Villager]>
    }
    
    func transform(input: Input, disposeBag: DisposeBag) -> Output {
        let villagerList = BehaviorRelay<[Villager]>(value: [])
        
        input.didTapVillagerLongPress
            .compactMap { $0 }
            .compactMap { self.villagers[safe: $0.row] }
            .subscribe(onNext: { villager in
                self.coordinator?.transition(for: .villagerDetail(villager: villager))
            }).disposed(by: disposeBag)
        
        Items.shared.villagerHouseList
            .subscribe(onNext: { villagers in
                let sortedVillagers = villagers
                    .sorted(by: { $0.translations.localizedName() < $1.translations.localizedName() })
                self.villagers = sortedVillagers
                villagerList.accept(sortedVillagers)
        }).disposed(by: disposeBag)
        
        return Output(villagers: villagerList.asObservable())
    }
}

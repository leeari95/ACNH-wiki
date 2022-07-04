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
    
    struct Input {
        let didSelectItem: Observable<IndexPath>
    }
    
    struct Output {
        let villagers: Observable<[Villager]>
    }
    
    func transform(input: Input, disposeBag: DisposeBag) -> Output {
        let villagerList = BehaviorRelay<[Villager]>(value: [])
        
        input.didSelectItem
            .subscribe(onNext: { indexPath in
                print(self.villagers[indexPath.row].translations.kRko)
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

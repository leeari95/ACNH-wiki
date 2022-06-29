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
        
        Items.shared.villagerList.subscribe(onNext: { villagers in
            let newVillagers = villagers.filter {
                $0.translations.kRko == "젤리" || $0.translations.kRko == "애플"
                || $0.translations.kRko == "존" || $0.translations.kRko == "리처드"
                || $0.translations.kRko == "병태" || $0.translations.kRko == "잭슨"
                || $0.translations.kRko == "미애" || $0.translations.kRko == "스피카"
                || $0.translations.kRko == "타마" || $0.translations.kRko == "미첼"
            }
            self.villagers = newVillagers
            villagerList.accept(newVillagers)
        }).disposed(by: disposeBag)
        
        return Output(villagers: villagerList.asObservable())
    }
}

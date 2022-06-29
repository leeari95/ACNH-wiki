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
        
    }
    
    struct Output {
        let villagers: Observable<[Villager]>
    }
    
    func transform(input: Input, disposeBag: DisposeBag) -> Output {
        let villagerList = BehaviorRelay<[Villager]>(value: [])
        
        Items.shared.villagerList
            .subscribe(onNext: { villagers in
                let sortedVillagers = villagers
                    .sorted(by: { $0.translations.localizedName() < $1.translations.localizedName() })
                villagerList.accept(sortedVillagers)
            }).disposed(by: disposeBag)
        
        return Output(villagers: villagerList.asObservable())
    }
}

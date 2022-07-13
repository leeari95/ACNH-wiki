//
//  VillagersCellViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/29.
//

import Foundation
import RxSwift
import RxRelay

final class VillagersCellViewModel {
    
    private let villager: Villager
    private let likeStorage: VillagersLikeStorage
    private let houseStorage: VillagersHouseStorage
    
    init(
        villager: Villager,
        likeStorage: VillagersLikeStorage = CoreDataVillagersLikeStorage(),
        houseStorage: VillagersHouseStorage = CoreDataVillagersHouseStorage()
    ) {
        self.villager = villager
        self.likeStorage = likeStorage
        self.houseStorage = houseStorage
    }
    
    struct Input {
        let didTapHeart: Observable<Void>
        let didTapHouse: Observable<Void>
    }
    
    struct Output {
        let isLiked: Observable<Bool>
        let isResident: Observable<Bool>
    }
    
    func transform(input: Input, disposeBag: DisposeBag) -> Output {
        let isLiked = BehaviorRelay<Bool>(value: false)
        let isResident = BehaviorRelay<Bool>(value: false)
        
        Items.shared.villagerHouseList
            .subscribe(onNext: { villagers in
                isResident.accept(villagers.contains(where: { $0.name == self.villager.name }))
            }).disposed(by: disposeBag)
        
        Items.shared.villagerLikeList
            .subscribe(onNext: { villagers in
                isLiked.accept(villagers.contains(where: { $0.name == self.villager.name }))
            }).disposed(by: disposeBag)
        
        input.didTapHeart
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                HapticManager.shared.impact(style: .medium)
                Items.shared.updateVillagerLike(owner.villager)
                owner.likeStorage.update(owner.villager)
            }).disposed(by: disposeBag)

        input.didTapHouse
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                HapticManager.shared.impact(style: .medium)
                Items.shared.updateVillagerHouse(owner.villager)
                owner.houseStorage.update(owner.villager)
            }).disposed(by: disposeBag)
        
        return Output(
            isLiked: isLiked.asObservable(),
            isResident: isResident.asObservable()
        )
    }
}

//
//  VillagerDetailViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/04.
//

import Foundation
import RxSwift
import RxRelay

final class VillagerDetailViewModel {
    
    var coordinator: VillagersCoordinator?
    
    private let likeStorage: VillagersLikeStorage
    private let houseStorage: VillagersHouseStorage
    private let villager: Villager
    
    init(
        likeStorage: VillagersLikeStorage = CoreDataVillagersLikeStorage(),
        houseStorage: VillagersHouseStorage = CoreDataVillagersHouseStorage(),
        villager: Villager,
        coordinator: VillagersCoordinator?
    ) {
        self.likeStorage = likeStorage
        self.houseStorage = houseStorage
        self.villager = villager
        self.coordinator = coordinator
    }
    
    struct Input {
        let didTapHeart: Observable<Void>
        let didTapHouse: Observable<Void>
    }
    
    struct Output {
        let villager: Observable<Villager>
        let isLiked: Observable<Bool>
        let isResident: Observable<Bool>
    }
    
    func transform(input: Input, disposeBag: DisposeBag) -> Output {
        let isLiked = BehaviorRelay<Bool>(value: false)
        let isResident = BehaviorRelay<Bool>(value: false)
        
        Items.shared.villagerHouseList
            .withUnretained(self)
            .subscribe(onNext: { owner, villagers in
                isResident.accept(villagers.contains(where: { $0.name == owner.villager.name }))
            }).disposed(by: disposeBag)
        
        Items.shared.villagerLikeList
            .withUnretained(self)
            .subscribe(onNext: { owner, villagers in
                isLiked.accept(villagers.contains(where: { $0.name == owner.villager.name }))
            }).disposed(by: disposeBag)
        
        input.didTapHeart
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                Items.shared.updateVillagerLike(owner.villager)
                owner.likeStorage.update(owner.villager)
            }).disposed(by: disposeBag)
        
        input.didTapHouse
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                Items.shared.updateVillagerHouse(owner.villager)
                owner.houseStorage.update(owner.villager)
            }).disposed(by: disposeBag)
        
        return Output(
            villager: Observable.just(villager),
            isLiked: isLiked.asObservable(),
            isResident: isResident.asObservable()
        )
    }
}

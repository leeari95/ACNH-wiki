//
//  Items.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/08.
//

import Foundation
import OSLog
import RxSwift
import RxRelay

final class Items {
    static let shared = Items()
    
    // MARK: - Private
    private let network: APIProvider = DefaultAPIProvider()
    private let villagersLikeStorage = CoreDataVillagersLikeStorage()
    private let villagersHouseStorage = CoreDataVillagersHouseStorage()
    private let disposeBag = DisposeBag()
    
    private let villagers = BehaviorRelay<[Villager]>(value: [])
    private let villagersLike = BehaviorRelay<[Villager]>(value: [])
    private let villagersHouse = BehaviorRelay<[Villager]>(value: [])
    
    private let categories = BehaviorRelay<[Category: [Item]]>(value: [:])
    private let currentItemsCount = BehaviorRelay<[Category: Int]>(value: [:])
    private let isLoad = BehaviorRelay<Bool>(value: false)
    private let currentUserInfo = BehaviorRelay<UserInfo?>(value: nil)
    private let currentDailyTasks = BehaviorRelay<[DailyTask]>(value: [])
    private let userItems = BehaviorRelay<[Item]>(value: [])
    
    private init() {
        setUpUserCollection()
        fetchCatalog()
    }
    
    private func setUpUserCollection() {
        CoreDataUserInfoStorage().fetchUserInfo()
            .subscribe(onSuccess: { userInfo in
                self.currentUserInfo.accept(userInfo)
            }, onFailure: { error in
                debugPrint(error)
            }).disposed(by: disposeBag)
        
        CoreDataDailyTaskStorage().fetchTasks()
            .subscribe(onSuccess: { tasks in
                self.currentDailyTasks.accept(tasks)
            }, onFailure: { error in
                debugPrint(error)
            }).disposed(by: disposeBag)
        
        CoreDataVillagersLikeStorage().fetch()
            .subscribe(onSuccess: { villagers in
                self.villagersLike.accept(villagers)
            }, onFailure: { error in
                debugPrint(error)
            }).disposed(by: disposeBag)
        
        CoreDataVillagersHouseStorage().fetch()
            .subscribe(onSuccess: { villagers in
                self.villagersHouse.accept(villagers)
            }, onFailure: { error in
                debugPrint(error)
            }).disposed(by: disposeBag)
        
        CoreDataItemsStorage().fetch()
            .subscribe(onSuccess: { items in
                self.userItems.accept(items)
            }, onFailure: { error in
                debugPrint(error)
            }).disposed(by: disposeBag)
    }

    private func fetchCatalog() {
        let group = DispatchGroup()
        var itemList: [Category: [Item]] = [:]
        
        group.enter()
        network.requestList(VillagersRequest()) { result in
            switch result {
            case .success(let response):
                let items = response.map { $0.toDomain() }
                self.villagers.accept(items)
            case .failure(let error):
                os_log(
                    .error,
                    log: .default,
                    "⛔️ 주민을 가져오는데 실패했습니다.\n에러내용: \(error.localizedDescription)"
                )
            }
            group.leave()
        }
        group.enter()
        network.requestList(BugRequest()) { result in
            switch result {
            case .success(let response):
                let items = response.map { $0.toDomain() }
                itemList[.bugs] = items
            case .failure(let error):
                os_log(
                    .error,
                    log: .default,
                    "⛔️ 곤충을 가져오는데 실패했습니다.\n에러내용: \(error.localizedDescription)"
                )
            }
            group.leave()
        }
        group.enter()
        network.requestList(FishRequest()) { result in
            switch result {
            case .success(let response):
                let items = response.map { $0.toDomain() }
                itemList[.fishes] = items
            case .failure(let error):
                os_log(
                    .error,
                    log: .default,
                    "⛔️ 물고기를 가져오는데 실패했습니다.\n에러내용: \(error.localizedDescription)"
                )
            }
            group.leave()
        }
        group.enter()
        network.requestList(FossilsRequest()) { result in
            switch result {
            case .success(let response):
                let items = response.map { $0.toDomain() }
                itemList[.fossils] = items
            case .failure(let error):
                os_log(
                    .error,
                    log: .default,
                    "⛔️ 화석을 가져오는데 실패했습니다.\n에러내용: \(error.localizedDescription)"
                )
            }
            group.leave()
        }
        group.enter()
        network.requestList(ArtRequest()) { result in
            switch result {
            case .success(let response):
                let items = response.map { $0.toDomain() }
                itemList[.art] = items
            case .failure(let error):
                os_log(
                    .error,
                    log: .default,
                    "⛔️ 미술품을 가져오는데 실패했습니다.\n에러내용: \(error.localizedDescription)"
                )
            }
            group.leave()
        }
        group.enter()
        network.requestList(SeaCreaturesRequest()) { result in
            switch result {
            case .success(let response):
                let items = response.map { $0.toDomain() }
                itemList[.seaCreatures] = items
            case .failure(let error):
                os_log(
                    .error,
                    log: .default,
                    "⛔️ 해산물을 가져오는데 실패했습니다.\n에러내용: \(error.localizedDescription)"
                )
            }
            group.leave()
        }
        group.notify(queue: .main) {
            self.categories.accept(itemList)
            var itemsCount = [Category: Int]()
            itemList.forEach { (key: Category, value: [Item]) in
                itemsCount[key] = value.count
            }
            self.currentItemsCount.accept(itemsCount)
            self.isLoad.accept(true)
        }
    }
}

extension Items {
    
    var villagerList: Observable<[Villager]> {
        return self.villagers.asObservable()
    }
    
    var villagerHouseList: Observable<[Villager]> {
        return self.villagersHouse.asObservable()
    }
    
    var villagerLikeList: Observable<[Villager]> {
        return self.villagersLike.asObservable()
    }
    
    var categoryList: Observable<[Category: [Item]]> {
        return self.categories.asObservable()
    }
    var isLoading: Observable<Bool> {
        return self.isLoad.asObservable()
    }
    var userInfo: Observable<UserInfo?> {
        return self.currentUserInfo.asObservable()
    }
    
    var dailyTasks: Observable<[DailyTask]> {
        return self.currentDailyTasks.asObservable()
    }
    
    var itemList: Observable<[Item]> {
        return self.userItems.asObservable()
    }
    
    func updateUserInfo(_ userInfo: UserInfo) {
        self.currentUserInfo.accept(userInfo)
    }
    
    var itemsCount: Observable<[Category: Int]> {
        return currentItemsCount.asObservable()
    }
    
    func updateTasks(_ task: DailyTask) {
        var tasks = currentDailyTasks.value
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        } else {
            tasks.append(task)
        }
        self.currentDailyTasks.accept(tasks)
    }
    
    func deleteTask(_ task: DailyTask) {
        var tasks = currentDailyTasks.value
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks.remove(at: index)
        }
        self.currentDailyTasks.accept(tasks)
    }
    
    func updateVillagerHouse(_ villager: Villager) {
        var villagers = villagersHouse.value
        if let index = villagers.firstIndex(where: {$0.name == villager.name}) {
            villagers.remove(at: index)
        } else {
            villagers.append(villager)
        }
        villagersHouse.accept(villagers)
    }
    
    func updateVillagerLike(_ villager: Villager) {
        var villagers = villagersLike.value
        if let index = villagers.firstIndex(where: {$0.name == villager.name}) {
            villagers.remove(at: index)
        } else {
            villagers.append(villager)
        }
        villagersLike.accept(villagers)
    }
    
    func updateItem(_ item: Item) {
        var items = userItems.value
        if let index = items.firstIndex(where: { $0.name == item.name && $0.genuine == item.genuine }) {
            items.remove(at: index)
        } else {
            items.append(item)
        }
        userItems.accept(items)
    }
}

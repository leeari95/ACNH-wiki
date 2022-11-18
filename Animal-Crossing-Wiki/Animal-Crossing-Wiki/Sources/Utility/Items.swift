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
    private let disposeBag = DisposeBag()
    private let networkGroup = DispatchGroup()
    
    private let villagers = BehaviorRelay<[Villager]>(value: [])
    private let villagersLike = BehaviorRelay<[Villager]>(value: [])
    private let villagersHouse = BehaviorRelay<[Villager]>(value: [])
    
    private let categories = BehaviorRelay<[Category: [Item]]>(value: [:])
    private let allItems = BehaviorRelay<[Item]>(value: [])
    private let currentItemsCount = BehaviorRelay<[Category: Int]>(value: [:])
    private let isLoad = BehaviorRelay<Bool>(value: true)
    private let currentUserInfo = BehaviorRelay<UserInfo?>(value: nil)
    private let currentDailyTasks = BehaviorRelay<[DailyTask]>(value: [])
    private let userItems = BehaviorRelay<[Category: [Item]]>(value: [:])
    private let songs = BehaviorRelay<[Item]>(value: [])
    
    private(set) var materialsItemList: [String: Item] = [:]
    
    private init() {
        setUpUserCollection()
        fetchVillagers()
        fetchCritters()
        fetchFurniture()
        
        networkGroup.notify(queue: .main) {
            self.isLoad.accept(false)
            self.allItems.accept(self.categories.value.flatMap { $0.value })
            self.setUpMaterialsItems()
        }
    }
    
    private func setUpUserCollection() {
        currentUserInfo.accept(CoreDataUserInfoStorage().fetchUserInfo())
        
        CoreDataDailyTaskStorage().fetchTasks()
            .subscribe(onSuccess: { tasks in
                self.currentDailyTasks.accept(tasks)
            }, onFailure: { error in
                debugPrint(error)
            }).disposed(by: disposeBag)

        self.villagersLike.accept(CoreDataVillagersLikeStorage().fetch())
        self.villagersHouse.accept(CoreDataVillagersHouseStorage().fetch())
        
        CoreDataItemsStorage().fetch()
            .subscribe(onSuccess: { items in
                var userItems = [Category: [Item]]()
                items.forEach { item in
                    var items = userItems[item.category] ?? []
                    items.append(item)
                    userItems[item.category] = items
                }
                self.userItems.accept(userItems)
            }, onFailure: { error in
                debugPrint(error)
            }).disposed(by: disposeBag)
    }
    
    private func fetchVillagers() {
        networkGroup.enter()
        network.request(VillagersRequest()) { result in
            switch result {
            case .success(let response):
                let items = response.map { $0.toDomain() }
                    .sorted(by: { $0.translations.localizedName() < $1.translations.localizedName() })
                self.villagers.accept(items)
            case .failure(let error):
                os_log(
                    .error,
                    log: .default,
                    "⛔️ 주민을을 가져오는데 실패했습니다.\n에러내용: \(error.localizedDescription)"
                )
            }
            self.networkGroup.leave()
        }
    }
    
    private func fetchCritters() {
        networkGroup.enter()
        let group = DispatchGroup()
        var itemList: [Category: [Item]] = [:]
        group.enter()
        network.request(BugRequest()) { result in
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
        network.request(FishRequest()) { result in
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
        network.request(FossilsRequest()) { result in
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
        network.request(SeaCreaturesRequest()) { result in
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
            self.updateAllItemList(by: itemList)
            self.networkGroup.leave()
        }
    }

    private func fetchFurniture() {
        self.networkGroup.enter()
        let group = DispatchGroup()
        var itemList: [Category: [Item]] = [:]
        
        group.enter()
        network.request(ArtRequest()) { result in
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
        network.request(HousewaresRequest()) { result in
            switch result {
            case .success(let response):
                let items = response.map { $0.toDomain() }
                itemList[.housewares] = items
            case .failure(let error):
                os_log(
                    .error,
                    log: .default,
                    "⛔️ 가구을 가져오는데 실패했습니다.\n에러내용: \(error.localizedDescription)"
                )
            }
            group.leave()
        }
        group.enter()
        network.request(MiscellaneousRequest()) { result in
            switch result {
            case .success(let response):
                let items = response.map { $0.toDomain() }
                itemList[.miscellaneous] = items
            case .failure(let error):
                os_log(
                    .error,
                    log: .default,
                    "⛔️ 잡화를 가져오는데 실패했습니다.\n에러내용: \(error.localizedDescription)"
                )
            }
            group.leave()
        }
        group.enter()
        network.request(WallMountedRequest()) { result in
            switch result {
            case .success(let response):
                let items = response.map { $0.toDomain() }
                itemList[.wallMounted] = items
            case .failure(let error):
                os_log(
                    .error,
                    log: .default,
                    "⛔️ 벽걸이를 가져오는데 실패했습니다.\n에러내용: \(error.localizedDescription)"
                )
            }
            group.leave()
        }
        group.enter()
        network.request(CeilingDecorRequest()) { result in
            switch result {
            case .success(let response):
                let items = response.map { $0.toDomain() }
                itemList[.ceilingDecor] = items
            case .failure(let error):
                os_log(
                    .error,
                    log: .default,
                    "⛔️ 천장을 가져오는데 실패했습니다.\n에러내용: \(error.localizedDescription)"
                )
            }
            group.leave()
        }
        group.enter()
        network.request(WallpaperRequest()) { result in
            switch result {
            case .success(let response):
                let items = response.map { $0.toDomain() }
                itemList[.wallpaper] = items
            case .failure(let error):
                os_log(
                    .error,
                    log: .default,
                    "⛔️ 벽지를 가져오는데 실패했습니다.\n에러내용: \(error.localizedDescription)"
                )
            }
            group.leave()
        }
        group.enter()
        network.request(FloorsRequest()) { result in
            switch result {
            case .success(let response):
                let items = response.map { $0.toDomain() }
                itemList[.floors] = items
            case .failure(let error):
                os_log(
                    .error,
                    log: .default,
                    "⛔️ 바닥을 가져오는데 실패했습니다.\n에러내용: \(error.localizedDescription)"
                )
            }
            group.leave()
        }
        group.enter()
        network.request(RugsRequest()) { result in
            switch result {
            case .success(let response):
                let items = response.map { $0.toDomain() }
                itemList[.rugs] = items
            case .failure(let error):
                os_log(
                    .error,
                    log: .default,
                    "⛔️ 러그을 가져오는데 실패했습니다.\n에러내용: \(error.localizedDescription)"
                )
            }
            group.leave()
        }
        group.enter()
        network.request(OtherRequest()) { result in
            switch result {
            case .success(let response):
                let items = response.map { $0.toDomain() }
                    .filter { !($0.keyword.contains("Unnecessary") && $0.sell == -1) }
                itemList[.other] = items
            case .failure(let error):
                os_log(
                    .error,
                    log: .default,
                    "⛔️ 기타를 가져오는데 실패했습니다.\n에러내용: \(error.localizedDescription)"
                )
            }
            group.leave()
        }
        group.enter()
        network.request(RecipesRequest()) { result in
            switch result {
            case .success(let response):
                let items = response.map { $0.toDomain() }
                itemList[.recipes] = items
            case .failure(let error):
                os_log(
                    .error,
                    log: .default,
                    "⛔️ 레시피를 가져오는데 실패했습니다.\n에러내용: \(error.localizedDescription)"
                )
            }
            group.leave()
        }
        group.enter()
        network.request(SongsRequest()) { result in
            switch result {
            case .success(let response):
                let items = response.map { $0.toDomain() }
                    .sorted(by: { $0.translations.localizedName() < $1.translations.localizedName() })
                itemList[.songs] = items
            case .failure(let error):
                os_log(
                    .error,
                    log: .default,
                    "⛔️ 음악을 가져오는데 실패했습니다.\n에러내용: \(error.localizedDescription)"
                )
            }
            group.leave()
        }
        group.enter()
        network.request(PhotosReqeust()) { result in
            switch result {
            case .success(let response):
                let items = response.map { $0.toDomain() }
                    .sorted(by: { $0.translations.localizedName() < $1.translations.localizedName() })
                itemList[.photos] = items
            case .failure(let error):
                os_log(
                    .error,
                    log: .default,
                    "⛔️ 주민 사진을 가져오는데 실패했습니다.\n에러내용: \(error.localizedDescription)"
                )
            }
            group.leave()
        }
        group.enter()
        network.request(TopsRequest()) { result in
            switch result {
            case .success(let response):
                let items = response.map { $0.toDomain() }
                    .sorted(by: { $0.translations.localizedName() < $1.translations.localizedName() })
                itemList[.tops] = items
            case .failure(let error):
                os_log(
                    .error,
                    log: .default,
                    "⛔️ 상의를 가져오는데 실패했습니다.\n에러내용: \(error.localizedDescription)"
                )
            }
            group.leave()
        }
        group.notify(queue: .main) {
            self.updateAllItemList(by: itemList)
            self.networkGroup.leave()
        }
    }
    
    private func updateAllItemList(by items: [Category: [Item]]) {
        var currentItems = self.categories.value
        var itemsCount = self.currentItemsCount.value
        items.forEach { (category: Category, items: [Item]) in
            currentItems[category] = items
            itemsCount[category] = items.count
        }
        self.categories.accept(currentItems)
        self.currentItemsCount.accept(itemsCount)
    }
    
    private func setUpMaterialsItems() {
        let values = allItems.value
            .filter { $0.category == .recipes }
            .compactMap { $0.recipe?.materials.map { $0.key.description } }
        let materials = Array(Set(values.flatMap { $0 }))
        let materialsItems = allItems.value
            .filter { $0.category != .recipes && materials.contains($0.name) }
        self.materialsItemList = Dictionary(uniqueKeysWithValues: zip(materialsItems.map { $0.name }, materialsItems))
    }
}

// MARK: - Internal
extension Items {
    
    var villagerList: Observable<[Villager]> {
        return villagers.asObservable()
    }
    
    var villagerHouseList: Observable<[Villager]> {
        return villagersHouse.asObservable()
    }
    
    var villagerLikeList: Observable<[Villager]> {
        return villagersLike.asObservable()
    }
    
    var categoryList: Observable<[Category: [Item]]> {
        return categories.asObservable()
    }
    var isLoading: Observable<Bool> {
        return isLoad.asObservable()
    }
    var userInfo: Observable<UserInfo?> {
        return currentUserInfo.asObservable()
    }
    
    var dailyTasks: Observable<[DailyTask]> {
        return currentDailyTasks.asObservable()
    }
    
    var itemList: Observable<[Category: [Item]]> {
        return userItems.asObservable()
    }
    
    func updateUserInfo(_ userInfo: UserInfo) {
        currentUserInfo.accept(userInfo)
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
        var currentUserItems = userItems.value
        var items = currentUserItems[item.category] ?? []
        if let index = items.firstIndex(of: item) {
            items.remove(at: index)
        } else {
            items.append(item)
        }
        currentUserItems[item.category] = items
        userItems.accept(currentUserItems)
    }
    
    func itemFilter(keyword: String, category: Keyword) -> [Item] {
        let items = allItems.value
        return items
            .filter { $0.keyword.contains(keyword) }
            .sorted(by: {$0.category.rawValue < $1.category.rawValue })
    }
    
    func reset() {
        villagersLike.accept([])
        villagersHouse.accept([])
        let currentItems = userItems.value.map { $0.key }
        var resetItem = userItems.value
        currentItems.forEach { category in
            resetItem[category] = []
        }
        userItems.accept(resetItem)
        currentUserInfo.accept(UserInfo())
        currentDailyTasks.accept(DailyTask.tasks)
    }
    
    func allCheckItem(category: Category) {
        var items = userItems.value
        let allItems = categories.value[category]
        var newItems: [Item]
        if let currentItems = items[category] {
            newItems = allItems?.filter { currentItems.contains($0) == false } ?? []
        } else {
            newItems = allItems ?? []
        }
        items[category, default: []].append(contentsOf: newItems)
        userItems.accept(items)
    }
    
    func resetCheckItem(category: Category) {
        var items = userItems.value
        items[category, default: []] = []
        userItems.accept(items)
    }
    
}

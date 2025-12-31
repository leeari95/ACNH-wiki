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
import RxCocoa

final class Items {
    static let shared = Items()

    // MARK: - Private
    private let network: APIProvider = DefaultAPIProvider()
    private let disposeBag = DisposeBag()
    private let networkGroup = DispatchGroup()

    private let villagers = BehaviorRelay<[Villager]>(value: [])
    private let villagersLike = BehaviorRelay<[Villager]>(value: [])
    private let villagersHouse = BehaviorRelay<[Villager]>(value: [])
    private let npc = BehaviorRelay<[NPC]>(value: [])
    private let npcLike = BehaviorRelay<[NPC]>(value: [])
    private let randomVisitNPCList = BehaviorRelay<[NPC]>(value: [])
    private let fixedVisitNPCList = BehaviorRelay<[NPC]>(value: [])
    private let currentAnimalCount = BehaviorRelay<[Category: Int]>(value: [:])

    private let categories = BehaviorRelay<[Category: [Item]]>(value: [:])
    private let allItems = BehaviorRelay<[Item]>(value: [])
    private let currentItemsCount = BehaviorRelay<[Category: Int]>(value: [:])
    private let isLoad = BehaviorRelay<Bool>(value: true)
    private let currentUserInfo = BehaviorRelay<UserInfo?>(value: nil)
    private let currentDailyTasks = BehaviorRelay<[DailyTask]>(value: [])
    private let userItems = BehaviorRelay<[Category: [Item]]>(value: [:])
    private let songs = BehaviorRelay<[Item]>(value: [])

    private(set) var materialsItemList: [String: Item] = [:]
    
    var list: [Item] { allItems.value }

    var fixedVisitNpcs: Driver<[NPC]> { fixedVisitNPCList.asDriver() }
    var randomVisitNpcs: Driver<[NPC]> { randomVisitNPCList.asDriver() }

    private init() {
        setUpUserCollection()
        fetchAnimals()
        fetchCritters()
        fetchFurniture()
        fetchClothes()

        networkGroup.notify(queue: .main) {
            self.isLoad.accept(false)
            self.allItems.accept(self.categories.value.flatMap { $0.value })
            self.setUpMaterialsItems()
        }
        
        npc.subscribe(with: self) { owner, list in
            let randomVisitNPCList = list.filter(\.isRandomVisit)
            let fixedVisitNPCList = list.filter(\.isFixedVisit)
            owner.randomVisitNPCList.accept(randomVisitNPCList)
            owner.fixedVisitNPCList.accept(fixedVisitNPCList)
        }
        .disposed(by: disposeBag)
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
        self.npcLike.accept(CoreDataNPCLikeStorage().fetch())

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

    // MARK: Fetch Items
    private func fetchAnimals() {
        networkGroup.enter()
        let group = DispatchGroup()
        fetchItem(VillagersRequest(), group: group) { [weak self] response in
            let items = response.map { $0.toDomain() }
                .sorted(by: { $0.translations.localizedName() < $1.translations.localizedName() })
            self?.villagers.accept(items)
        }
        fetchItem(NPCRequest(), group: group) { [weak self] response in
            let items = response.map { $0.toDomain() }
                .sorted(by: { $0.translations.localizedName() < $1.translations.localizedName() })
            self?.npc.accept(items)
        }
        
        group.notify(queue: .main) {
            self.currentAnimalCount.accept([
                .villager: self.villagers.value.count,
                .npc: self.npc.value.count
            ])
            self.networkGroup.leave()
        }
    }

    private func fetchCritters() {
        networkGroup.enter()
        let group = DispatchGroup()
        var itemList: [Category: [Item]] = [:]
        
        fetchItem(BugRequest(), itemKey: .bugs, group: group) {
            itemList.merge($0) { _, new in new }
        }
        fetchItem(FishRequest(), itemKey: .fishes, group: group) {
            itemList.merge($0) { _, new in new }
        }
        fetchItem(FossilsRequest(), itemKey: .fossils, group: group) {
            itemList.merge($0) { _, new in new }
        }
        fetchItem(SeaCreaturesRequest(), itemKey: .seaCreatures, group: group) {
            itemList.merge($0) { _, new in new }
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

        fetchItem(ArtRequest(), itemKey: .art, group: group) {
            itemList.merge($0) { _, new in new }
        }
        fetchItem(ToolsRequest(), itemKey: .tools, group: group) {
            itemList.merge($0) { _, new in new }
        }
        fetchItem(HousewaresRequest(), itemKey: .housewares, group: group) {
            itemList.merge($0) { _, new in new }
        }
        fetchItem(MiscellaneousRequest(), itemKey: .miscellaneous, group: group) {
            itemList.merge($0) { _, new in new }
        }
        fetchItem(WallMountedRequest(), itemKey: .wallMounted, group: group) {
            itemList.merge($0) { _, new in new }
        }
        fetchItem(CeilingDecorRequest(), itemKey: .ceilingDecor, group: group) {
            itemList.merge($0) { _, new in new }
        }
        fetchItem(WallpaperRequest(), itemKey: .wallpaper, group: group) {
            itemList.merge($0) { _, new in new }
        }
        fetchItem(FloorsRequest(), itemKey: .floors, group: group) {
            itemList.merge($0) { _, new in new }
        }
        fetchItem(RugsRequest(), itemKey: .rugs, group: group) {
            itemList.merge($0) { _, new in new }
        }
        fetchItem(OtherRequest(), itemKey: .other, group: group) {
            itemList.merge($0) { _, new in new }
        }
        fetchItem(RecipesRequest(), itemKey: .recipes, group: group) {
            itemList.merge($0) { _, new in new }
        }
        fetchItem(SongsRequest(), itemKey: .songs, group: group) {
            itemList.merge($0) { _, new in new }
        }
        fetchItem(PhotosReqeust(), itemKey: .photos, group: group) {
            itemList.merge($0) { _, new in new }
        }
        fetchItem(FencingReqeust(), itemKey: .fencing, group: group) {
            itemList.merge($0) { _, new in new }
        }
        fetchItem(GyroidsRequst(), itemKey: .gyroids, group: group) {
            itemList.merge($0) { _, new in new }
        }
        
        group.notify(queue: .main) {
            self.updateAllItemList(by: itemList)
            self.networkGroup.leave()
        }
    }

    private func fetchClothes() {
        self.networkGroup.enter()
        let group = DispatchGroup()
        var itemList: [Category: [Item]] = [:]
        
        fetchItem(TopsRequest(), itemKey: .tops, group: group) {
            itemList.merge($0) { _, new in new }
        }
        fetchItem(BottomsRequest(), itemKey: .bottoms, group: group) {
            itemList.merge($0) { _, new in new }
        }
        fetchItem(DressUpRequest(), itemKey: .dressUp, group: group) {
            itemList.merge($0) { _, new in new }
        }
        fetchItem(HeadwearRequest(), itemKey: .headwear, group: group) {
            itemList.merge($0) { _, new in new }
        }
        fetchItem(AccessoriesRequest(), itemKey: .accessories, group: group) {
            itemList.merge($0) { _, new in new }
        }
        fetchItem(SocksRequest(), itemKey: .socks, group: group) {
            itemList.merge($0) { _, new in new }
        }
        fetchItem(ShoesRequest(), itemKey: .shoes, group: group) {
            itemList.merge($0) { _, new in new }
        }
        fetchItem(BagsRequest(), itemKey: .bags, group: group) {
            itemList.merge($0) { _, new in new }
        }
        fetchItem(UmbrellasRequest(), itemKey: .umbrellas, group: group) {
            itemList.merge($0) { _, new in new }
        }
        fetchItem(WetSuitRequest(), itemKey: .wetSuit, group: group) {
            itemList.merge($0) { _, new in new }
        }
        fetchItem(ReactionsRequest(), itemKey: .reactions, group: group) {
            itemList.merge($0) { _, new in new }
        }

        group.notify(queue: .main) {
            self.updateAllItemList(by: itemList)
            self.networkGroup.leave()
        }
    }

    private func fetchItem<T: APIRequest>(
        _ request: T,
        itemKey: Category,
        group: DispatchGroup,
        completion: @escaping ([Category: [Item]]) -> Void
    ) where T.Response: Collection, T.Response.Element: DomainConvertible {
        fetchItem(request, group: group) { response in
            let items = response.map { $0.toDomain() }
            completion([itemKey: items])
        }
    }
    
    private func fetchItem<T: APIRequest>(
        _ request: T,
        group: DispatchGroup,
        completion: @escaping (T.Response) -> Void
    ) where T.Response: Collection {
        group.enter()
        network.request(request) { result in
            defer { group.leave() }
            
            switch result {
            case .success(let response):
                completion(response)

            case .failure(let error):
                os_log(
                    .error,
                    log: .default,
                    "⛔️ %@ - 가져오는데 실패했습니다.\n에러내용: %@", String(describing: request), error.localizedDescription
                )
            }
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
    
    var npcList: Observable<[NPC]> {
        return npc.asObservable()
    }

    var npcLikeList: Observable<[NPC]> {
        return npcLike.asObservable()
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

    func count(isItem: Bool = true) -> Observable<[Category: Int]> {
        return (isItem ? currentItemsCount : currentAnimalCount).asObservable()
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

    func updateNPCLike(_ npc: NPC) {
        var npcLikeList = npcLike.value
        if let index = npcLikeList.firstIndex(where: {$0.name == npc.name}) {
            npcLikeList.remove(at: index)
        } else {
            npcLikeList.append(npc)
        }
        npcLike.accept(npcLikeList)
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

    func updateItemVariants(_ item: Item) {
        var currentUserItems = userItems.value
        var items = currentUserItems[item.category] ?? []
        if let index = items.firstIndex(of: item) {
            items[index] = item
            currentUserItems[item.category] = items
            userItems.accept(currentUserItems)
        }
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

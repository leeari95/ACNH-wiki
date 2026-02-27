# Data Flow

## Central Hub: Items.shared

**File**: `Utility/Items.swift`

앱의 모든 데이터가 `Items.shared` 싱글톤을 통해 흐름:

```
┌──────────┐     ┌───────────────┐     ┌───────────────┐
│  APIs    │────→│ Items.shared  │←────│  CoreData     │
│ (fetch)  │     │ BehaviorRelay │     │  (user data)  │
└──────────┘     └───────┬───────┘     └───────────────┘
                         │ Observable streams
                         ▼
                 ┌───────────────┐
                 │   Reactors    │
                 │ (subscribe)   │
                 └───────┬───────┘
                         │ State binding
                         ▼
                 ┌───────────────┐
                 │      UI       │
                 └───────────────┘
```

## 앱 시작 시 데이터 로드

`Items.init()` (앱 시작 시 1회):

1. **CoreData 로드** (`setUpUserCollection()`):
   - `CoreDataUserInfoStorage().fetchUserInfo()` → `currentUserInfo`
   - `CoreDataDailyTaskStorage().fetchTasks()` → `currentDailyTasks`
   - `CoreDataVillagersLikeStorage().fetch()` → `villagersLike`
   - `CoreDataVillagersHouseStorage().fetch()` → `villagersHouse`
   - `CoreDataItemsStorage().fetch()` → `userItems`
   - `CoreDataVariantsStorage().fetchAll()` → `collectedVariants`

2. **API 호출** (4개 그룹, DispatchGroup 사용):
   - `fetchAnimals()` → Villagers, NPCs
   - `fetchCritters()` → Fish, Bugs, Sea Creatures, Fossils
   - `fetchFurniture()` → 15 카테고리 (Art, Housewares, Songs 등)
   - `fetchClothes()` → 11 카테고리 (Tops, Shoes 등)

3. **완료 시** (`networkGroup.notify`):
   - `isLoad` → false
   - `allItems` 조합
   - `materialsItemList` 구축 (레시피 재료 매핑)

## API → Domain Model Flow

```
APIRequest struct (BugRequest 등)
    ↓ DefaultAPIProvider.request()
Alamofire AF.request()
    ↓ responseDecodable
ResponseDTO (BugResponseDTO, Decodable)
    ↓ .toDomain() (DomainConvertible protocol)
Domain Model (Item)
    ↓ BehaviorRelay.accept()
Items.shared.categories (Observable stream)
```

**Network retry**: 3회 재시도, exponential backoff (2초, 4초, 6초)

## User Action → Persistence Flow

```
User taps "collect item"
    ↓
Reactor.action.onNext(.toggleItem(item))
    ↓ mutate()
Items.shared.updateItem(item)     → BehaviorRelay 업데이트 (UI 즉시 반영)
CoreDataItemsStorage().update(item) → CoreData background context 저장
    ↓
Reactor.state 변경 → UI 업데이트
```

## Observable Streams

Reactor에서 구독 가능한 `Items.shared` 스트림:

| Stream | Type | 설명 |
|--------|------|------|
| `categoryList` | `Observable<[Category: [Item]]>` | 전체 아이템 (API 데이터) |
| `isLoading` | `Observable<Bool>` | 네트워크 로딩 상태 |
| `userInfo` | `Observable<UserInfo?>` | 플레이어 프로필 |
| `dailyTasks` | `Observable<[DailyTask]>` | 일일 체크리스트 |
| `itemList` | `Observable<[Category: [Item]]>` | 사용자가 수집한 아이템 |
| `villagerList` | `Observable<[Villager]>` | 전체 주민 목록 |
| `villagerLikeList` | `Observable<[Villager]>` | 좋아요한 주민 |
| `villagerHouseList` | `Observable<[Villager]>` | 섬에 사는 주민 |
| `npcList` | `Observable<[NPC]>` | 전체 NPC |
| `npcLikeList` | `Observable<[NPC]>` | 좋아요한 NPC |
| `variantList` | `Observable<[String: Set<String>]>` | 수집한 변형 |
| `count(isItem:)` | `Observable<[Category: Int]>` | 카테고리별 아이템 수 |
| `fixedVisitNpcs` | `Driver<[NPC]>` | 고정 방문 NPC |
| `randomVisitNpcs` | `Driver<[NPC]>` | 랜덤 방문 NPC |

## Update Methods

| Method | 동작 |
|--------|------|
| `updateItem(_:)` | 수집 아이템 토글 (있으면 제거, 없으면 추가) |
| `updateVillagerLike(_:)` | 주민 좋아요 토글 |
| `updateVillagerHouse(_:)` | 섬 주민 토글 |
| `updateNPCLike(_:)` | NPC 좋아요 토글 |
| `updateTasks(_:)` | 일일 태스크 추가/수정 |
| `deleteTask(_:)` | 일일 태스크 삭제 |
| `updateUserInfo(_:)` | 프로필 업데이트 |
| `updateVariant(_:itemName:isAdding:)` | 변형 수집 토글 |
| `allCheckItem(category:)` | 카테고리 전체 체크 |
| `resetCheckItem(category:)` | 카테고리 전체 리셋 |
| `reset()` | 전체 데이터 초기화 |

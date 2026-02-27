# Catalog Feature (+ Animals 공유 구조)

아이템 카탈로그와 동물 목록을 동일한 CatalogReactor로 처리.

## Shared CatalogReactor

`CatalogReactor`는 **하나의 클래스가 두 탭에서 재사용**됨:

```
Catalog 탭:    CatalogReactor(delegate: CatalogCoordinator, mode: .item)
Animals 탭:    CatalogReactor(delegate: AnimalsCoordinator, mode: .animals)
```

두 Coordinator 모두 `CatalogReactorDelegate`를 채택:

```swift
protocol CatalogReactorDelegate: AnyObject {
    func showItemList(category: Category)
    func showSearchList()
}
```

## Catalog Tab Structure

```
Presentation/Catalog/
├── Coordinator/CatalogCoordinator.swift
├── ViewControllers/
│   ├── CatalogViewController.swift    # 카테고리 그리드
│   ├── ItemsViewController.swift      # 아이템 목록 (필터/검색)
│   └── ItemDetailViewController.swift # 아이템 상세
└── ViewModels/
    ├── CatalogReactor.swift           # 공유 Reactor
    ├── ItemsReactor.swift             # 아이템 목록
    ├── ItemDetailReactor.swift        # 아이템 상세
    └── ItemsCellReactor.swift         # 셀 Reactor
```

## Animals Tab Structure

```
Presentation/Animals/
├── Coordinator/AnimalsCoordinator.swift
├── ViewControllers/
│   ├── VillagersViewController.swift    # 주민 목록 (검색/필터)
│   ├── VillagerDetailViewController.swift
│   ├── NPCViewController.swift
│   └── NPCDetailViewController.swift
└── ViewModels/
    ├── VillagersReactor.swift           # 주민 필터링 + 초성 검색
    ├── VillagerDetailReactor.swift
    ├── NPCReactor.swift
    └── NPCDetailReactor.swift
```

## CatalogCoordinator Routes

| Route | 설명 |
|-------|------|
| `.items(for: Category)` | 카테고리별 아이템 목록 |
| `.itemDetail(Item)` | 아이템 상세 |
| `.keyword(title:keyword:)` | 키워드 필터 |
| `.search` | 검색 모드 |

## AnimalsCoordinator Routes

| Route | 설명 |
|-------|------|
| `.animals(for: Category)` | .villager 또는 .npc 분기 |
| `.detailVillager(Villager)` | 주민 상세 |
| `.detailNPC(NPC)` | NPC 상세 |

## ItemsReactor Mode

`ItemsReactor`는 Mode enum으로 동작 분기:

```swift
enum Mode: Equatable {
    case user           // 사용자 수집 아이템
    case all            // 전체 아이템
    case keyword(title: String, category: Keyword)  // 키워드 필터
    case search         // 검색
}
```

## 주의사항

CatalogReactor 수정 시 **Catalog 탭과 Animals 탭 양쪽에 영향**이 있음.
→ [gotchas.md](../gotchas.md) #5

# Glossary

## Naming Conventions

| Component | Pattern | Location | Example |
|-----------|---------|----------|---------|
| Reactor (ViewModel) | `XxxReactor` | `ViewModels/` | `VillagersReactor` |
| Cell Reactor | `XxxCellReactor` | `ViewModels/` | `VillagersCellReactor` |
| Section Reactor | `XxxSectionReactor` | `ViewModels/` | `TodaysTasksSectionReactor` |
| ViewController | `XxxViewController` | `ViewControllers/` | `VillagersViewController` |
| View | `XxxView` | `Views/` | `VillagerDetailView` |
| Coordinator | `XxxCoordinator` | `Coordinator/` | `AnimalsCoordinator` |
| Storage Protocol | `XxxStorage` | `CoreDataStorage/XxxStorage/` | `ItemsStorage` |
| Storage Impl | `CoreDataXxxStorage` | `CoreDataStorage/XxxStorage/` | `CoreDataItemsStorage` |
| Entity Mapping | `XxxEntity+Mapping.swift` | `CoreDataStorage/.../EntityMapping/` | `ItemEntity+Mapping.swift` |
| API Request | `XxxRequest` | `Networking/Request/` | `BugRequest` |
| Response DTO | `XxxResponseDTO` | `Networking/Response/` | `BugResponseDTO` |
| Reactor Delegate | `XxxReactorDelegate` | Reactor 파일 내 | `CatalogReactorDelegate` |

## Nested Enums

Reactor, Coordinator 내부에 중첩 enum 사용:

```swift
// Reactor 내부
enum Action { }
enum Mutation { }
struct State { }

// Coordinator 내부
enum Route { }
```

## Domain Terms

| Term | 의미 |
|------|------|
| Critter | Fish + Bug + Sea Creature (수집 가능한 생물) |
| Villager | 섬에 거주하는 동물 주민 |
| NPC | 고정/랜덤 방문 NPC (여울, K.K. 등) |
| Category | 30개 아이템 분류 enum (`Category.swift`) |
| Turnip Prices | 무 시세 예측 미니게임 |
| DailyTask | 사용자 정의 일일 체크리스트 |
| UserInfo | 플레이어 프로필 (이름, 섬이름, 과일, 반구) |
| Catalog | 게임 내 아이템 도감 |
| Hemisphere | 북반구/남반구 (생물 출현 시기 결정) |
| Variant | 아이템의 색상/패턴 변형 |

## Framework Terms

| Term | 의미 |
|------|------|
| `BehaviorRelay` | RxRelay의 mutable state wrapper. `Items.shared`에서 상태 저장용 |
| `Single` | RxSwift one-shot async 타입. CoreDataStorage의 fetch 반환 타입 |
| `Driver` | RxCocoa의 UI 바인딩 전용 Observable (MainThread, no error) |
| `DomainConvertible` | Response DTO → `Item` 변환 프로토콜 (`toDomain()`) |
| `CoordinatorType` | Coordinator 식별 enum. child 관리에 사용 |
| `Reactor` | ReactorKit 프로토콜. Action-Mutation-State 단방향 흐름 |
| `DisposeBag` | RxSwift 구독 수명 관리. ViewController마다 하나씩 보유 |

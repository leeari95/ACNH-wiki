# ACNH-wiki 아키텍처 가이드

코드 리뷰 시 참고할 수 있는 ACNH-wiki 프로젝트 아키텍처 가이드입니다.

## 레이어 구조

```
Presentation (UIKit, RxSwift, ReactorKit)
  6 features: Dashboard, Catalog, Animals, Collection, MusicPlayer, TurnipPrices
      |
Utility / Extension (RxSwift, UIKit)
      |
CoreDataStorage (CoreData, RxSwift)
      |
Networking (Alamofire, RxSwift)
      |
Models (Foundation only)
```

**의존성 흐름은 상위에서 하위 방향만 허용. 순환 의존성 없음.**

### 레이어 규칙

| Layer | 허용 Import | 금지 Import |
|-------|------------|------------|
| Models | Foundation only | 모든 프레임워크 |
| Networking | Foundation, Alamofire, RxSwift | Presentation, CoreDataStorage |
| CoreDataStorage | Foundation, CoreData, RxSwift | Presentation, Networking |
| Utility | Foundation, RxSwift, RxRelay, AVFoundation | Presentation (1 예외) |
| Presentation | UIKit, RxSwift, ReactorKit, RxDataSources | Networking, CoreDataStorage 직접 |

> **알려진 위반**: 13개 Presentation Reactor 파일이 CoreData 클래스를 기본 파라미터로 참조. Allowlisted.

---

## ReactorKit 패턴

### 기본 구조

```swift
final class XxxReactor: Reactor {
    enum Action { }      // 사용자 이벤트 (버튼 탭, 텍스트 입력 등)
    enum Mutation { }    // 상태 변경 단위
    struct State { }     // 뷰에 바인딩되는 데이터

    let initialState: State

    func mutate(action: Action) -> Observable<Mutation>  // Action -> Mutation 변환
    func reduce(state: State, mutation: Mutation) -> State  // Mutation -> State 적용
}
```

**Flow**: UI event -> `reactor.action.onNext(.xxx)` -> `mutate()` -> `Observable<Mutation>` -> `reduce()` -> `State` -> UI 업데이트

### mutate() 규칙

- `Observable<Mutation>`을 반환
- Items.shared 스트림 구독이 일반적
- Side effect (API 호출, CoreData 업데이트)는 여기서 처리

```swift
func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .fetch:
        let categories = Items.shared.count()
            .map { Mutation.setCategories($0) }
        let loading = Items.shared.isLoading
            .map { Mutation.setLoadingState($0) }
        return .merge([categories, loading])
    case .toggleItem(let item):
        Items.shared.updateItem(item)
        return .empty()
    }
}
```

### reduce() 규칙

- 순수 함수 (State 변환만)
- **예외**: `coordinator?.transition(for:)` 호출은 프로젝트 관례로 허용

```swift
func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .setCategories(let categories):
        newState.categories = categories
    case .selected(let menu):
        coordinator?.transition(for: .detail(menu))  // 허용된 관례
    }
    return newState
}
```

### ViewController bind(to:) 패턴

```swift
func bind(to reactor: XxxReactor) {
    // 1. Action 바인딩: UI -> Reactor
    self.rx.viewDidLoad
        .map { XxxReactor.Action.fetch }
        .bind(to: reactor.action)
        .disposed(by: disposeBag)

    // 2. State 바인딩: Reactor -> UI
    reactor.state.map { $0.items }
        .bind(to: collectionView.rx.items(...))
        .disposed(by: disposeBag)

    reactor.state.map { $0.isLoading }
        .bind(to: loadingView.rx.isAnimating)
        .disposed(by: disposeBag)
}
```

> **예외**: IconChooserVC, TurnipPriceResultVC는 bind(to:) 없이 동작 (allowlisted).

---

## Coordinator 패턴

### 프로토콜

```swift
protocol Coordinator: AnyObject {
    var type: CoordinatorType { get }
    var childCoordinators: [Coordinator] { get set }
    func start()
    func childDidFinish(_ child: Coordinator?)
}

enum CoordinatorType {
    case main, dashboard, taskEdit, animals, catalog, collection, turnipPrices
}
```

### 표준 구조

```swift
final class XxxCoordinator: Coordinator {
    enum Route {
        case detail(Item)
        case pop
        case dismiss
    }

    var type: CoordinatorType = .xxx
    var rootViewController: UINavigationController
    var childCoordinators: [Coordinator] = []

    func start() {
        let viewController = XxxViewController()
        viewController.bind(to: XxxReactor(coordinator: self))
        rootViewController.addChild(viewController)
    }

    func transition(for route: Route) {
        switch route {
        case .detail(let item):
            let vc = DetailViewController()
            vc.bind(to: DetailReactor(item: item, coordinator: self))
            rootViewController.pushViewController(vc, animated: true)
        case .pop:
            rootViewController.popViewController(animated: true)
        case .dismiss:
            rootViewController.dismiss(animated: true)
        }
    }
}
```

### Reactor-Coordinator 통신 패턴

**Pattern A: Direct Reference** (대부분의 Reactor)
```swift
final class SomeReactor: Reactor {
    var coordinator: SomeCoordinator?

    init(coordinator: SomeCoordinator) {
        self.coordinator = coordinator
    }
}
```

**Pattern B: Delegate Protocol** (재사용 Reactor)
```swift
protocol CatalogReactorDelegate: AnyObject {
    func showItemList(category: Category)
}

final class CatalogReactor: Reactor {
    weak var delegate: CatalogReactorDelegate?
}

// CatalogCoordinator + AnimalsCoordinator 모두 채택
```

---

## Items.shared 데이터 허브

### 중앙 데이터 흐름

```
APIs (fetch) --> Items.shared (BehaviorRelay) <-- CoreData (user data)
                       |
                 Observable streams
                       |
                    Reactors (subscribe)
                       |
                      UI (binding)
```

### 주요 스트림

| Stream | Type | 설명 |
|--------|------|------|
| `categoryList` | `Observable<[Category: [Item]]>` | 전체 아이템 |
| `isLoading` | `Observable<Bool>` | 네트워크 로딩 상태 |
| `userInfo` | `Observable<UserInfo?>` | 플레이어 프로필 |
| `dailyTasks` | `Observable<[DailyTask]>` | 일일 체크리스트 |
| `itemList` | `Observable<[Category: [Item]]>` | 수집한 아이템 |
| `villagerList` | `Observable<[Villager]>` | 전체 주민 목록 |
| `villagerLikeList` | `Observable<[Villager]>` | 좋아요한 주민 |

### 업데이트 메서드

| Method | 동작 |
|--------|------|
| `updateItem(_:)` | 수집 아이템 토글 |
| `updateVillagerLike(_:)` | 주민 좋아요 토글 |
| `updateVillagerHouse(_:)` | 섬 주민 토글 |
| `updateUserInfo(_:)` | 프로필 업데이트 |

---

## Networking 아키텍처

### APIRequest / APIProvider 패턴

```swift
// 요청 정의
struct BugRequest: APIRequest {
    typealias Response = [BugResponseDTO]
    // URLConvertible, URLRequestConvertible 준수
}

// 요청 실행
DefaultAPIProvider().request(BugRequest())
    .map { $0.map { $0.toDomain() } }

// Response DTO -> Domain Model
extension BugResponseDTO: DomainConvertible {
    func toDomain() -> Item { ... }
}
```

### API 엔드포인트

| API | Base URL | 용도 |
|-----|----------|------|
| GitHub Raw | `EnvironmentsVariable.repoURL` | 아이템, 주민, NPC JSON |
| Turnip API | `EnvironmentsVariable.turnupURL` | 무 시세 |
| ACNH API | `EnvironmentsVariable.acnhAPI` | 노래 |

---

## Feature 구조

### 표준 구조

```
Feature/
  Coordinator/XxxCoordinator.swift
  ViewControllers/XxxViewController.swift
  ViewModels/XxxReactor.swift
  Views/XxxView.swift
```

### 예외 사항

| Feature | 특이사항 |
|---------|----------|
| TurnipPrices | flat 구조 (하위 폴더 없음) - 의도된 구조 |
| MusicPlayer | Coordinator 없음 - AppCoordinator가 관리 |
| Dashboard/Views/shared/ | 앱 전체에서 사용되는 공유 UI 컴포넌트 위치 |

---

## Tab Bar 구조

```
AppCoordinator (UITabBarController)
  Tab 1: DashboardCoordinator   -> "Dashboard"
  Tab 2: CatalogCoordinator     -> "Catalog"
  Tab 3: AnimalsCoordinator     -> "animals"
  Tab 4: TurnipPricesCoordinator -> "turnipPrices"
  Tab 5: CollectionCoordinator  -> "Collection"
    + PlayerViewController (탭바 위 오버레이)
```

---

## External Dependencies

| Library | Version | Linking | Purpose |
|---------|---------|---------|---------|
| RxSwift | 6.8.0 | `.framework` (dynamic) | 반응형 프로그래밍 |
| RxCocoa | 6.8.0 | `.framework` (dynamic) | UIKit 바인딩 |
| RxDataSources | 5.0.0 | `.framework` (dynamic) | TableView/CollectionView |
| ReactorKit | 3.2.0 | `.framework` (dynamic) | MVVM 아키텍처 |
| Alamofire | 5.10.0 | - | HTTP 네트워킹 |
| Kingfisher | 7.10.2 | - | 이미지 로딩/캐싱 |
| Firebase | - | - | Analytics + Crashlytics |

> RxSwift 관련 패키지는 반드시 `.framework` (dynamic). 변경 시 런타임 크래시 발생.

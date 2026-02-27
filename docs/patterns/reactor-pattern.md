# ReactorKit Pattern

## Structure

모든 ViewModel은 ReactorKit의 `Reactor` 프로토콜을 채택:

```swift
final class XxxReactor: Reactor {
    enum Action { }      // 사용자 이벤트 (버튼 탭, 텍스트 입력 등)
    enum Mutation { }    // 상태 변경 단위
    struct State { }     // 뷰에 바인딩되는 데이터

    let initialState: State

    func mutate(action: Action) -> Observable<Mutation>  // Action → Mutation 변환
    func reduce(state: State, mutation: Mutation) -> State  // Mutation → State 적용
}
```

**Flow**: UI event → `reactor.action.onNext(.xxx)` → `mutate()` → `Observable<Mutation>` → `reduce()` → `State` → UI 업데이트

## Coordinator Communication (2 Patterns)

### Pattern A: Direct Reference

Reactor가 Coordinator를 직접 참조. 대부분의 Reactor에서 사용.

```swift
// DashboardReactor.swift
final class DashboardReactor: Reactor {
    var coordinator: DashboardCoordinator?

    init(coordinator: DashboardCoordinator) {
        self.coordinator = coordinator
    }

    func reduce(state: State, mutation: Mutation) -> State {
        switch mutation {
        case .selected(let menu):
            coordinator?.transition(for: .about)  // reduce 안에서 호출
        }
        return state
    }
}
```

사용처: `DashboardReactor`, `ItemsReactor`, `VillagersReactor`, `CollectionReactor`, `TurnipPricesReactor` 등

### Pattern B: Delegate Protocol

Reactor가 delegate 프로토콜을 정의하고, Coordinator가 이를 채택. **하나의 Reactor를 여러 Coordinator에서 재사용**할 때 사용.

```swift
// CatalogReactor.swift
protocol CatalogReactorDelegate: AnyObject {
    func showItemList(category: Category)
    func showSearchList()
}

final class CatalogReactor: Reactor {
    weak var delegate: CatalogReactorDelegate?

    init(delegate: CatalogReactorDelegate, mode: Mode = .item) {
        self.delegate = delegate
    }

    func reduce(state: State, mutation: Mutation) -> State {
        switch mutation {
        case .showItemList(let category):
            delegate?.showItemList(category: category)
        // ...
        }
    }
}
```

사용처: `CatalogReactor` (CatalogCoordinator + AnimalsCoordinator에서 공유)

> **새 Reactor 작성 시**: 단일 Coordinator 전용이면 Pattern A, 여러 Coordinator에서 재사용할 가능성이 있으면 Pattern B 선택.

## Items.shared 스트림 사용

Reactor의 `mutate()`에서 `Items.shared`의 Observable 스트림을 구독하는 것이 일반적:

```swift
func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .fetch:
        let categories = Items.shared.count()
            .map { Mutation.setCategories($0) }
        let loading = Items.shared.isLoading
            .map { Mutation.setLoadingState($0) }
        return .merge([categories, loading])
    }
}
```

주요 스트림: → [data-flow.md](data-flow.md) 참고

## bind(to:) 바인딩 패턴

ViewController는 `bind(to:)` 메서드에서 Reactor와 양방향 바인딩:

```swift
func bind(to reactor: VillagersReactor) {
    // 1. Action 바인딩: UI → Reactor
    self.rx.viewDidLoad
        .map { VillagersReactor.Action.fetch }
        .bind(to: reactor.action)
        .disposed(by: disposeBag)

    // 2. State 바인딩: Reactor → UI
    reactor.state.map { $0.villagers }
        .bind(to: collectionView.rx.items(...))
        .disposed(by: disposeBag)

    reactor.state.map { $0.isLoading }
        .bind(to: activityIndicator.rx.isAnimating)
        .disposed(by: disposeBag)
}
```

## Multi-Reactor ViewController

Dashboard처럼 복잡한 화면은 부모 Reactor + 여러 자식 Reactor를 사용:

```swift
// DashboardCoordinator.swift:40-51
viewController.bind(to: DashboardReactor(coordinator: self))
viewController.setUpViewModels(
    userInfoVM: UserInfoReactor(coordinator: self),
    tasksVM: TodaysTasksSectionReactor(coordinator: self),
    villagersVM: VillagersSectionReactor(coordinator: self),
    progressVM: CollectionProgressSectionReactor(coordinator: self),
    fixeVisitdNPCListVM: NpcsSectionReactor(state: .init(), mode: .fixedVisit, coordinator: self),
    randomVisitNPCListVM: NpcsSectionReactor(state: .init(), mode: .randomVisit, coordinator: self)
)
```

## Reference Files

| 복잡도 | File | 특징 |
|--------|------|------|
| Simple | `Presentation/Dashboard/ViewModels/DashboardReactor.swift` | State 없음, 라우팅만 |
| Medium | `Presentation/Catalog/ViewModels/CatalogReactor.swift` | Delegate 패턴, Mode enum |
| Complex | `Presentation/Animals/ViewModels/VillagersReactor.swift` | 다중 데이터소스, 필터링, 초성 검색 |

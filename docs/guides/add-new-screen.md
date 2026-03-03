# Add a New Screen

기존 feature에 새 화면을 추가하는 단계별 가이드.

## Steps

### 1. Reactor 생성

`Presentation/{Feature}/ViewModels/XxxReactor.swift`:

```swift
import Foundation
import ReactorKit

final class XxxReactor: Reactor {
    enum Action {
        case fetch
    }

    enum Mutation {
        case setData(_ data: [SomeType])
        case setLoading(_ isLoading: Bool)
    }

    struct State {
        var data: [SomeType] = []
        var isLoading: Bool = true
    }

    let initialState: State
    var coordinator: FeatureCoordinator?  // 또는 weak var delegate: XxxReactorDelegate?

    init(coordinator: FeatureCoordinator, state: State = State()) {
        self.coordinator = coordinator
        self.initialState = state
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetch:
            let data = Items.shared.someStream.map { Mutation.setData($0) }
            let loading = Items.shared.isLoading.map { Mutation.setLoading($0) }
            return .merge([data, loading])
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setData(let data):
            newState.data = data
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        }
        return newState
    }
}
```

### 2. ViewController 생성

`Presentation/{Feature}/ViewControllers/XxxViewController.swift`:

```swift
import UIKit
import RxSwift

final class XxxViewController: UIViewController {
    private let disposeBag = DisposeBag()

    func bind(to reactor: XxxReactor) {
        // Action 바인딩
        self.rx.viewDidLoad
            .map { XxxReactor.Action.fetch }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // State 바인딩
        reactor.state.map { $0.isLoading }
            .bind(to: activityIndicator.rx.isAnimating)
            .disposed(by: disposeBag)
    }
}
```

### 3. Custom View 생성 (필요 시)

`Presentation/{Feature}/Views/XxxView.swift`

### 4. Route 추가

해당 feature의 Coordinator에 Route case 추가:

```swift
// XxxCoordinator.swift
enum Route {
    // ... 기존 routes
    case newScreen(param: SomeType)  // 새 route 추가
}
```

### 5. transition() 구현

```swift
func transition(for route: Route) {
    switch route {
    // ... 기존 cases
    case .newScreen(let param):
        let viewController = XxxViewController()
        viewController.bind(to: XxxReactor(param: param, coordinator: self))
        rootViewController.pushViewController(viewController, animated: true)
    }
}
```

### 6. 기존 Reactor에서 Route 트리거

```swift
// 호출하는 측 Reactor의 reduce()
case .someAction:
    coordinator?.transition(for: .newScreen(param: data))
```

## Checklist

- [ ] Reactor: Action, Mutation, State 정의
- [ ] Reactor: `mutate()`, `reduce()` 구현
- [ ] ViewController: `bind(to:)` 메서드 구현
- [ ] Coordinator: Route case 추가
- [ ] Coordinator: `transition(for:)` case 구현
- [ ] 로컬라이제이션: `ko.lproj` + `en.lproj` 문자열 추가
- [ ] SwiftLint: `swiftlint --config .swiftlint.yml` 통과

## 참고: TurnipPrices 예외

TurnipPrices feature는 하위 폴더 없이 flat 구조. 이 feature에 추가 시 flat으로 유지할 것.
→ [gotchas.md](../gotchas.md) #2

# Coordinator Pattern

## Protocol

```swift
// Sources/Coordinator.swift
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

> 새 feature Coordinator 추가 시 `CoordinatorType`에 case 추가 필요.

## Standard Structure

```swift
final class XxxCoordinator: Coordinator {
    // 1. Route 정의
    enum Route {
        case detail(Item)
        case pop
        case dismiss
    }

    // 2. Properties
    var type: CoordinatorType = .xxx
    var rootViewController: UINavigationController
    var childCoordinators: [Coordinator] = []
    private(set) var parentCoordinator: Coordinator?

    // 3. start() - 루트 VC 생성 + Reactor 바인딩
    func start() {
        let viewController = XxxViewController()
        viewController.bind(to: XxxReactor(coordinator: self))
        rootViewController.addChild(viewController)
    }

    // 4. transition(for:) - Route별 화면 전환
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

## VC 생성 패턴 in transition()

Coordinator가 **VC 생성 → Reactor 생성 + 바인딩 → Navigation**을 모두 담당:

```swift
// push
let viewController = ItemsViewController()
viewController.bind(to: ItemsReactor(category: category, coordinator: self))
rootViewController.pushViewController(viewController, animated: true)

// present (modal)
let viewController = PreferencesViewController()
viewController.bind(to: PreferencesReactor(coordinator: self))
let nav = UINavigationController(rootViewController: viewController)
rootViewController.present(nav, animated: true)
```

## Delegation Variants

### Variant A: Reactor → Coordinator (Direct)

```swift
// Reactor holds coordinator directly
var coordinator: DashboardCoordinator?
coordinator?.transition(for: .about)
```

### Variant B: Reactor → Coordinator (via Delegate)

```swift
// Reactor defines delegate protocol
protocol CatalogReactorDelegate: AnyObject {
    func showItemList(category: Category)
}

// Coordinator adopts delegate
extension CatalogCoordinator: CatalogReactorDelegate {
    func showItemList(category: Category) {
        transition(for: .items(for: category))
    }
}

// AnimalsCoordinator ALSO adopts same delegate
extension AnimalsCoordinator: CatalogReactorDelegate {
    func showItemList(category: Category) {
        transition(for: .animals(for: category))
    }
}
```

이 패턴으로 `CatalogReactor`가 Catalog 탭과 Animals 탭에서 재사용됨.

## Reference Files

| Coordinator | 특징 | File |
|-------------|------|------|
| `DashboardCoordinator` | 가장 복잡 (13 routes, modal+push, alert, delegate) | `Presentation/Dashboard/Coordinator/` |
| `CatalogCoordinator` | CatalogReactorDelegate 구현, search route | `Presentation/Catalog/Coordinator/` |
| `AnimalsCoordinator` | CatalogReactorDelegate 공유, 간결 | `Presentation/Animals/Coordinator/` |
| `AppCoordinator` | TabBar + MusicPlayer 오버레이 관리 | `Sources/AppCoordinator.swift` |

# Gotchas

코드 수정 전 반드시 확인해야 할 함정 목록.

## 1. RxSwift는 반드시 Dynamic Framework

`Tuist/Package.swift`에서 Rx 관련 패키지는 모두 `.framework`로 설정해야 함.
`.staticFramework`로 변경하면 런타임 크래시 발생:

```
failed to demangle superclass of _RXDelegateProxy
```

해당 패키지: RxSwift, RxCocoa, RxDataSources, ReactorKit

## 2. TurnipPrices는 flat 구조

`Presentation/TurnipPrices/` 안에 Coordinator/, ViewControllers/ 등 하위 폴더가 **없음**.
11개 파일이 플랫하게 존재. 이것은 의도된 구조이므로 재구성하지 말 것.

## 3. reduce() 안에서 Coordinator 호출

일부 Reactor는 `reduce()` 안에서 `coordinator?.transition(for:)`을 호출함.
이는 기술적으로 impure하지만 **프로젝트의 기존 관례**. 따를 것, 리팩터링하지 말 것.

```swift
// DashboardReactor.swift:51-63
func reduce(state: State, mutation: Mutation) -> State {
    switch mutation {
    case .selected(let menu):
        switch menu {
        case .about: coordinator?.transition(for: .about)  // side effect in reduce
        // ...
```

## 4. Items.swift는 SwiftLint 제외 대상

`.swiftlint.yml`의 `excluded` 목록에 `Items.swift`, `AppDelegate.swift`, `SceneDelegate.swift`가 포함됨.
이 파일들에 SwiftLint 규칙을 강제 적용하려 하지 말 것.

SwiftLint 규칙 상세(네이밍, 길이 제한, 비활성화 규칙 등)는 [build-and-run.md — SwiftLint 규칙 상세](guides/build-and-run.md#swiftlint-규칙-상세) 참조.

## 5. CatalogReactor는 두 탭에서 공유

`CatalogReactor`는 하나의 클래스지만 두 탭에서 재사용됨:
- **Catalog 탭**: `CatalogReactor(delegate: CatalogCoordinator, mode: .item)`
- **Animals 탭**: `CatalogReactor(delegate: AnimalsCoordinator, mode: .animals)`

두 Coordinator 모두 `CatalogReactorDelegate`를 채택. 수정 시 양쪽 탭에 미치는 영향을 확인할 것.

## 6. 공유 UI 컴포넌트 위치

`LoadingView`, `EmptyView`, `ProgressView` 등은 `Presentation/Dashboard/Views/shared/`에 위치.
Dashboard 폴더 안이지만 **앱 전체에서 사용**됨. 이동하지 말 것.

## 7. 로컬라이제이션 패턴

`NSLocalizedString`을 직접 쓰지 말고 `String` extension 사용:

```swift
"key text".localized  // String+extension.swift에 정의
```

새 문자열 추가 시 **반드시** 양쪽 파일 모두 업데이트:
- `Resources/ko.lproj/Localizable.strings`
- `Resources/en.lproj/Localizable.strings`

## 8. CoreData는 CloudKit Container

`CoreDataStorage.swift`가 `NSPersistentCloudKitContainer`를 사용.
스키마 변경 시 lightweight migration 범위 내에서만 가능 (속성 추가, 옵셔널 변경 등).
관계(relationship) 변경이나 속성 타입 변경은 마이그레이션 계획 필요.

## 9. Tuist 버전

`.mise.toml`에 `tuist = "4.115.1"` 지정. 항상 `mise x -- tuist` 접두어로 명령어 실행.
직접 `tuist` 호출 시 다른 버전이 실행될 수 있음.

## 10. MusicPlayer에는 Coordinator가 없음

`PlayerViewController`는 **AppCoordinator**가 직접 관리.
탭바 위에 오버레이로 표시되며 `showMusicPlayer()`, `minimize()`, `maximize()`, `removePlayerViewController()`로 제어.
별도 Coordinator를 만들지 말 것.

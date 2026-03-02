# ACNH-wiki 코딩 컨벤션 상세 가이드

이 문서는 코드 리뷰 시 참고할 수 있는 ACNH-wiki 프로젝트의 상세한 코딩 컨벤션 규칙입니다.

## 기본 규칙

### SwiftLint
- [SwiftLint](https://github.com/realm/SwiftLint) 규칙을 기본으로 따름
- 프로젝트에 적용된 룰: `.swiftlint.yml`
- **제외 대상**: `Items.swift`, `AppDelegate.swift`, `SceneDelegate.swift` (gotchas.md #4)

---

## 1. 메모리 관리

### 1.1 weak self 바인딩 시 `owner` 네이밍

**규칙**: `[weak self]`를 바인딩할 때 **반드시** `owner`로 네이밍

이 규칙은 두 가지 상황 모두에 적용됩니다:

**A) guard let 언랩핑**

```swift
// 올바른 코드
Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] in
    guard let owner = self else { return }
    owner.repeatCount += 1
}

// 잘못된 코드 - [weak self] 누락 위험
closure = { [weak self] in
    guard let self = self else { return }
    self.doSomething()
}

// 잘못된 코드 - 변수명이 너무 김
closure = { [weak self] in
    guard let strongSelf = self else { return }
    strongSelf.doSomething()
}
```

**B) subscribe(with:) / drive(with:) 클로저 파라미터**

```swift
// 올바른 코드 - 파라미터 이름을 owner로 지정
reactor.state.map { $0.items }
    .subscribe(with: self) { owner, items in
        owner.updateUI(items)
    }
    .disposed(by: disposeBag)

reactor.state.map { $0.isLoading }
    .drive(with: self) { owner, isLoading in
        owner.loadingView.isHidden = !isLoading
    }
    .disposed(by: disposeBag)

// 잘못된 코드 - 파라미터 이름이 owner가 아님
reactor.state.map { $0.items }
    .subscribe(with: self) { vc, items in  // vc 대신 owner 사용
        vc.updateUI(items)
    }
    .disposed(by: disposeBag)

// 잘못된 코드 - $0 사용
reactor.state.map { $0.items }
    .subscribe(with: self) {
        $0.updateUI($1)  // $0 대신 owner 사용
    }
    .disposed(by: disposeBag)
```

**이유**:
- `guard let self = self`는 `[weak self]` 누락 실수 가능성
- 프로젝트 전체에서 `owner` 네이밍을 일관되게 사용하여 가독성과 검색 용이성 확보
- `subscribe(with:)`, `drive(with:)`의 첫 번째 파라미터도 동일하게 `owner`로 통일

### 1.2 RxSwift subscribe(with:), drive(with:)

**규칙**: `subscribe(with:)`, `drive(with:)` 사용 권장

```swift
// 올바른 코드
reactor.state.map { $0.items }
    .subscribe(with: self) { owner, items in
        owner.updateUI(items)
    }
    .disposed(by: disposeBag)

// 기존 방식도 허용
reactor.state.map { $0.items }
    .subscribe(onNext: { [weak self] items in
        guard let owner = self else { return }
        owner.updateUI(items)
    })
    .disposed(by: disposeBag)
```

---

## 2. RxSwift 스타일

### 2.1 subscribe(with:) trailing closure

**규칙**: `subscribe(with:)`에서 next 이벤트만 처리 시 trailing closure 사용

```swift
// 올바른 코드
reactor.state.map { $0.isLoading }
    .drive(with: self) { owner, isLoading in
        owner.loadingView.isHidden = !isLoading
    }
    .disposed(by: disposeBag)

// 잘못된 코드
reactor.state.map { $0.isLoading }
    .drive(with: self, onNext: { owner, isLoading in
        owner.loadingView.isHidden = !isLoading
    })
    .disposed(by: disposeBag)
```

### 2.2 disposed(by:) 줄바꿈

**규칙**: 클로저 닫는 괄호 `}` 다음에 줄바꿈하여 `.disposed(by: disposeBag)`를 새로운 줄에 작성

```swift
// 올바른 코드
reactor.state.map { $0.items }
    .bind(to: collectionView.rx.items(...)) { ... }
    }                              // <- } 다음에 줄바꿈
    .disposed(by: disposeBag)      // <- 새로운 줄에 작성

// 잘못된 코드
reactor.state.map { $0.items }
    .bind(to: collectionView.rx.items(...)) { ... }
    }.disposed(by: disposeBag)     // <- } 바로 뒤에 같은 줄에 작성
```

**핵심**: `}.disposed(by:)` -> `}\n.disposed(by:)`

### 2.3 guard 문 다음 한 줄 비우기

**규칙**: `guard` 문 다음에 한 줄 비우기

```swift
// 올바른 코드
.do(onNext: { [weak self] in
    guard let owner = self else { return }

    owner.updateUI()
})

// 잘못된 코드
.do(onNext: { [weak self] in
    guard let owner = self else { return }
    owner.updateUI()  // Missing blank line
})
```

**주의**: diff 또는 실제 코드를 확인하여 빈 줄이 실제로 없는지 정확히 확인해야 함

### 2.4 guard 문 본문 줄바꿈

**규칙**: `guard` 문의 `else { return }` 부분을 한 줄에 이어 쓰지 말고, `else` 블록을 줄바꿈하여 작성

```swift
// 올바른 코드
guard let self, let window, self.cloudImportToast == nil else {
    return
}

guard let owner = self else {
    return
}

guard let item = items.first else {
    return
}

// 잘못된 코드 - 한 줄 처리
guard let self, let window, self.cloudImportToast == nil else { return }

guard let owner = self else { return }

guard let item = items.first else { return }
```

**이유**: 조건이 길어질수록 한 줄 처리 시 가독성이 떨어지고, 디버깅 시 breakpoint 설정이 어려움. 일관성을 위해 짧은 guard 문도 동일하게 줄바꿈 처리.

**Priority**: P2

---

## 3. 로컬라이제이션

### 3.1 .localized 패턴

**규칙**: `NSLocalizedString`을 직접 쓰지 말고 `String` extension 사용

```swift
// 올바른 코드
"key text".localized  // String+extension.swift에 정의

// 잘못된 코드
NSLocalizedString("key text", comment: "")
```

### 3.2 양쪽 lproj 파일 업데이트

새 문자열 추가 시 **반드시** 양쪽 파일 모두 업데이트:
- `Resources/ko.lproj/Localizable.strings`
- `Resources/en.lproj/Localizable.strings`

---

## 4. ReactorKit 패턴

### 4.1 Reactor 구조

```swift
// 올바른 코드
final class XxxReactor: Reactor {
    enum Action { }      // 사용자 이벤트
    enum Mutation { }    // 상태 변경 단위
    struct State { }     // 뷰에 바인딩되는 데이터

    let initialState: State

    func mutate(action: Action) -> Observable<Mutation>
    func reduce(state: State, mutation: Mutation) -> State
}
```

### 4.2 bind(to:) 바인딩

```swift
// 올바른 코드
func bind(to reactor: XxxReactor) {
    // Action 바인딩
    self.rx.viewDidLoad
        .map { XxxReactor.Action.fetch }
        .bind(to: reactor.action)
        .disposed(by: disposeBag)

    // State 바인딩
    reactor.state.map { $0.items }
        .bind(to: collectionView.rx.items(...))
        .disposed(by: disposeBag)
}
```

### 4.3 Coordinator 전환은 reduce()에서

**프로젝트 관례**: `reduce()` 안에서 `coordinator?.transition(for:)` 호출은 허용

```swift
func reduce(state: State, mutation: Mutation) -> State {
    switch mutation {
    case .selected(let menu):
        coordinator?.transition(for: .about)  // 허용 (gotchas.md #3)
    }
    return state
}
```

---

## 5. Coordinator 패턴

### 5.1 화면 전환은 반드시 Coordinator를 통해

```swift
// 올바른 코드 (Coordinator에서)
func transition(for route: Route) {
    let vc = DetailViewController()
    vc.bind(to: DetailReactor(item: item, coordinator: self))
    rootViewController.pushViewController(vc, animated: true)
}

// 잘못된 코드 (ViewController에서 직접)
func showDetail() {
    let vc = DetailViewController()
    present(vc, animated: true)  // Coordinator를 통해야 함!
}
```

---

## 6. 데이터 접근

### 6.1 Items.shared를 통한 데이터 접근

```swift
// 올바른 코드
func mutate(action: Action) -> Observable<Mutation> {
    return Items.shared.categoryList
        .map { Mutation.setCategories($0) }
}

// 잘못된 코드 - 직접 CoreData 접근
func mutate(action: Action) -> Observable<Mutation> {
    return CoreDataItemsStorage().fetch()
        .map { Mutation.setItems($0) }
}
```

---

## 7. 접근 제한자 (Access Control)

### 7.1 final class 사용

**규칙**: 상속이 필요없다면 `final class` 선언

```swift
// 올바른 코드
final class MyViewController: UIViewController { ... }
final class MyReactor: Reactor { ... }

// 잘못된 코드
class MyViewController: UIViewController { ... }
```

### 7.2 private func in Extension

**규칙**: `private extension` 대신 각 함수별로 `private func` 선언

```swift
// 올바른 코드
extension MyVC {
    private func setupUI() { ... }
}

// 잘못된 코드
private extension MyVC {
    func setupUI() { ... }
}
```

---

## 8. MARK 주석

**규칙**: `extension`으로 프로토콜 확장 시 `// MARK: -` 주석 작성

```swift
// 올바른 코드
// MARK: - UICollectionViewDataSource
extension MyVC: UICollectionViewDataSource { ... }

// 잘못된 코드
extension MyVC: UICollectionViewDataSource { ... }  // Missing MARK
```

---

## 9. 네이밍

### 9.1 메서드 내 단일 객체 네이밍

**규칙**: 메서드 내부에서 단일 객체 생성 시 객체 타입으로 간결하게 네이밍

```swift
// 올바른 코드
func showDetail(item: Item) {
    let viewController = DetailViewController()
    let reactor = DetailReactor(item: item, coordinator: self)
    viewController.bind(to: reactor)
}

// 잘못된 코드
func showDetail(item: Item) {
    let detailViewController = DetailViewController()  // Just use viewController
    let detailReactor = DetailReactor(...)  // Just use reactor
}
```

### 9.2 삼항연산자에서 void 함수 호출 금지

```swift
// 잘못된 코드
flag ? showItems() : hideItems()

// 올바른 코드
if flag {
    showItems()
} else {
    hideItems()
}
```

---

## 요약 체크리스트

코드 리뷰 시 다음 항목들을 순차적으로 확인:

- [ ] `[weak self]` 언랩핑 시 `owner` 사용
- [ ] RxSwift `subscribe(with:)`, `drive(with:)` 활용
- [ ] `.disposed(by:)` 줄바꿈: `}` 바로 뒤가 아닌 새로운 줄에 작성
- [ ] `guard` 문 다음 한 줄 비우기
- [ ] 로컬라이제이션: `.localized` 사용, 양쪽 lproj 업데이트
- [ ] 화면 전환은 Coordinator를 통해
- [ ] 데이터 접근은 Items.shared를 통해
- [ ] 상속 불필요 시 `final class`
- [ ] `extension` 사용 시 `// MARK: -` 주석
- [ ] `private` 접근제한자는 각 함수별 선언
- [ ] SwiftLint 규칙 위반 확인

**리뷰 시 주의사항**:
- disposed(by:): `}` 바로 뒤에 같은 줄에 있으면 안됨
- guard문: diff에서 빈 줄 실제 존재 여부 정확히 확인
- Items.swift, AppDelegate.swift, SceneDelegate.swift는 SwiftLint 제외 대상
- TurnipPrices는 flat 구조 (gotchas.md #2)
- 코드 전체 맥락 고려하여 판단

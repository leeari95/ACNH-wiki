# Architecture

## Layer Diagram

```
┌─────────────────────────────────────────────────┐
│  Presentation (UIKit, RxSwift, ReactorKit)      │
│  6 features: Dashboard, Catalog, Animals,       │
│  Collection, MusicPlayer, TurnipPrices          │
├────────────────────┬────────────────────────────┤
│  Utility           │  Extension                 │
│  (RxSwift,RxRelay) │  (UIKit, Kingfisher)       │
├────────────────────┴────────────────────────────┤
│  CoreDataStorage (CoreData, RxSwift)            │
├─────────────────────────────────────────────────┤
│  Networking (Alamofire, RxSwift)                │
├─────────────────────────────────────────────────┤
│  Models (Foundation only)                       │
└─────────────────────────────────────────────────┘
```

**Dependency flow is top-down only. No circular dependencies exist.**

## Layers

### Models

- **Path**: `Projects/App/Sources/Models/`
- **Imports**: Foundation only
- **Role**: Pure domain value types
- **Key files**:
  - `Items/Item.swift` - 게임 아이템 (가구, 생물, 의류 등)
  - `Items/Category.swift` - 30개 카테고리 enum (CaseIterable)
  - `Villager.swift` - 마을 주민
  - `NPC.swift` - NPC (Identifiable)
  - `UserInfo.swift` - 플레이어 프로필
  - `DailyTask.swift` - 일일 체크리스트

### Networking

- **Path**: `Projects/App/Sources/Networking/`
- **Imports**: Foundation, Alamofire, RxSwift
- **Rule**: Response DTO는 `toDomain()`으로 Models 변환. Presentation을 import하지 않음.
- **Structure**:
  - `Protocol/APIRequest.swift` - 요청 정의 프로토콜 (URLConvertible, URLRequestConvertible)
  - `Protocol/APIProvider.swift` - 요청 실행 프로토콜 (callback + Single)
  - `DefaultAPIProvider.swift` - Alamofire 기반 구현체
  - `Request/` - 32개+ API 요청 구조체
  - `Response/` - Decodable DTO + `DomainConvertible` 프로토콜
  - `Utilities/EnvironmentsVariable.swift` - API base URL
  - `Utilities/APIError.swift` - 에러 enum
- **APIs**:
  - GitHub raw repo: `EnvironmentsVariable.repoURL` (아이템, 주민, NPC JSON)
  - Turnip API: `EnvironmentsVariable.turnupURL` (무 시세)
  - ACNH API: `EnvironmentsVariable.acnhAPI` (노래)

### CoreDataStorage

- **Path**: `Projects/App/Sources/CoreDataStorage/`
- **Imports**: Foundation, CoreData, CloudKit, RxSwift, OSLog
- **Rule**: Presentation, Networking을 import하지 않음. Entity ↔ Domain 변환은 매핑 extension에서 처리.
- **Pattern**: Storage 프로토콜 → CoreData 구현체 → Entity 매핑
- **Key files**:
  - `CoreDataStorage.swift` - 싱글톤. `NSPersistentCloudKitContainer`. 자동 lightweight migration. CloudKit 이벤트 감지, iCloud 계정 확인, Persistent History 정리. → [features/icloud-sync.md](features/icloud-sync.md)
  - `ItemsStorage/` - `ItemsStorage` 프로토콜 + `CoreDataItemsStorage` 구현
  - `UserInfoStorage/`, `DailyTaskStorage/`, `VariantsStorage/`, `VillagersLikeStorage/`, `VillagersHouseStorage/`, `NPCLikeStorage/`
- **Root entity**: `UserCollectionEntity` (모든 컬렉션의 부모)

### Utility

- **Path**: `Projects/App/Sources/Utility/`
- **Imports**: Foundation, RxSwift, RxRelay, RxCocoa, AVFoundation
- **Role**: 앱 전역 비즈니스 로직
- **Key files**:
  - `Items.swift` - **중앙 데이터 허브 싱글톤** (`Items.shared`). API 호출 + CoreData 로드 + BehaviorRelay 스트림 노출. → [data-flow.md](patterns/data-flow.md)
  - `MusicPlayerManager.swift` - 오디오 재생 싱글톤 (AVPlayer, MediaPlayer)
  - `TurnipPriceCalculator.swift` - 무 시세 예측 알고리즘
  - `HapticManager.swift` - 햅틱 피드백

### Extension

- **Path**: `Projects/App/Sources/Extension/`
- **Imports**: UIKit, RxSwift, RxCocoa, Kingfisher
- **Role**: 재사용 가능한 Swift extension
- **Key files**:
  - `String+extension.swift` - `.localized` (NSLocalizedString 래퍼), `.chosung` (한국어 초성 검색)
  - `Reactor+extension.swift` - `rx.viewDidLoad` 이벤트
  - `UI/ToastManager.swift` - 전용 UIWindow 기반 토스트 매니저 (레퍼런스 카운팅, 타임아웃)
  - `UI/ToastView.swift` - 캡슐형 토스트 UI (ActivityIndicator + Label, slide 애니메이션)
  - `UI/` - UIView, UIImage, UIColor 등 UIKit extension 15개+

### Presentation

- **Path**: `Projects/App/Sources/Presentation/`
- **Imports**: UIKit, RxSwift, ReactorKit, RxDataSources, Kingfisher
- **Rule**: Networking, CoreDataStorage를 직접 import하지 않음. `Items.shared`를 통해 데이터 접근.
- **6 Features**: → 각각 [features/](features/) 문서 참고

| Feature | Coordinator | 구조 | 비고 |
|---------|------------|------|------|
| Dashboard | DashboardCoordinator | 표준 (하위 폴더) | 6 VC, 12 Reactor. 가장 복잡 |
| Catalog | CatalogCoordinator | 표준 | CatalogReactorDelegate 공유 |
| Animals | AnimalsCoordinator | 표준 | CatalogReactor(.animals) 재사용 |
| Collection | CollectionCoordinator | 표준 | 수집 진행도 |
| MusicPlayer | 없음 (AppCoordinator 관리) | 표준 | Coordinator 부재 |
| TurnipPrices | TurnipPricesCoordinator | **flat (하위 폴더 없음)** | 비표준 구조 |

**표준 feature 구조**:
```
Feature/
├── Coordinator/XxxCoordinator.swift
├── ViewControllers/XxxViewController.swift
├── ViewModels/XxxReactor.swift
└── Views/XxxView.swift
```

### Root Files

- **Path**: `Projects/App/Sources/`
- `AppDelegate.swift` - Firebase/Crashlytics 초기화
- `SceneDelegate.swift` - UIWindow + AppCoordinator 생성. 신규 설치 시 CloudKit Import 대기, iCloud 계정/에러 알림, ToastManager 연동
- `CloudSyncSplashViewController.swift` - 신규 설치 시 CloudKit Import 대기 스플래시 화면
- `AppCoordinator.swift` - UITabBarController + 5개 탭 + MusicPlayer 오버레이 관리
- `Coordinator.swift` - `Coordinator` 프로토콜 + `CoordinatorType` enum
- `AppAppearance.swift` - 전역 UI 테마

## Tab Bar

```
AppCoordinator (UITabBarController)
├── Tab 1: DashboardCoordinator   → "Dashboard"
├── Tab 2: CatalogCoordinator     → "Catalog"
├── Tab 3: AnimalsCoordinator     → "animals"
├── Tab 4: TurnipPricesCoordinator → "turnipPrices"
└── Tab 5: CollectionCoordinator  → "Collection"
    + PlayerViewController (탭바 위 오버레이, minimize/maximize)
```

## Shared UI Components

- **Path**: `Projects/App/Sources/Presentation/Dashboard/Views/shared/`
- Dashboard 폴더 안에 있지만 **앱 전체에서 사용**됨
- LoadingView, EmptyView, ProgressView, ProgressBar, SectionView, SectionHeaderView, IconCell 등

## External Dependencies

| Library | Version | Linking | Purpose |
|---------|---------|---------|---------|
| RxSwift | 6.8.0 | `.framework` (dynamic) | 반응형 프로그래밍 |
| RxCocoa | 6.8.0 | `.framework` (dynamic) | UIKit 바인딩 |
| RxDataSources | 5.0.0 | `.framework` (dynamic) | TableView/CollectionView 데이터소스 |
| ReactorKit | 3.2.0 | `.framework` (dynamic) | MVVM 아키텍처 |
| Alamofire | 5.10.0 | - | HTTP 네트워킹 |
| Kingfisher | 7.10.2 | - | 이미지 로딩/캐싱 |
| Firebase | - | - | Analytics + Crashlytics |

> RxSwift 관련 패키지는 반드시 `.framework` (dynamic). → [gotchas.md](gotchas.md) #1

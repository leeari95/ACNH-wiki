# iCloud Sync (CloudKit)

## Overview

`NSPersistentCloudKitContainer`를 사용하여 여러 기기 간 수집 기록을 자동 동기화.
사용자 개입 없이 백그라운드에서 동작하며, Import 시 토스트 알림으로 상태를 안내.

## Architecture

```text
Device A                    CloudKit Server               Device B
┌──────────┐               ┌──────────────┐              ┌──────────┐
│ CoreData │──Export──────→│   iCloud     │──Import─────→│ CoreData │
│  save()  │               │  Container   │              │ viewCtx  │
└──────────┘               └──────────────┘              └──────────┘
                                                               │
                                                  NSPersistentStoreRemoteChange
                                                               │
                                                  Items.setUpUserCollection()
                                                               │
                                                  BehaviorRelay.accept()
                                                               │
                                                          UI 자동 갱신
```

## Key Files

| File | 역할 |
|------|------|
| `CoreDataStorage.swift` | `NSPersistentCloudKitContainer` 설정, CloudKit 이벤트 감지, iCloud 계정 확인, UC 중복 방지, Persistent History 정리 |
| `SceneDelegate.swift` | 신규 설치 감지 + CloudKit Import 대기, iCloud 계정/에러 알림, ToastManager 연동 |
| `Items.swift` | `didReceiveRemoteChanges` 구독 (debounce 2s) → `setUpUserCollection()` |
| `ToastManager.swift` | 전용 UIWindow 기반 토스트 매니저. 레퍼런스 카운팅, 타임아웃, 백그라운드 dismiss |
| `ToastView.swift` | Import 상태 토스트 UI (캡슐형 디자인, ActivityIndicator + Label, slide 애니메이션) |
| `CloudSyncSplashViewController.swift` | 신규 설치 시 CloudKit Import 대기 스플래시 화면 |

## Data Sync Flow

### Export (로컬 저장 → CloudKit)

```text
User taps "collect item"
    ↓
CoreDataItemsStorage.update() → context.saveContext()
    ↓
NSPersistentCloudKitContainer 자동 Export (1-5초)
    ↓
CloudKit Server에 반영
```

### Import (CloudKit → 다른 기기)

```text
CloudKit Silent Push 수신
    ↓
NSPersistentCloudKitContainer 자동 Import
    ↓
CoreDataStorage.handleCloudKitEvent() → didStartCloudImport 알림
    ↓
SceneDelegate → ToastManager.incrementAndShow() ("iCloud를 통해 수집 기록을 불러오는 중입니다.")
    ↓
Import 완료 → didFinishCloudImport 알림 → 토스트 dismiss
    ↓
NSPersistentStoreRemoteChange 알림
    ↓
Items.setUpUserCollection() → BehaviorRelay.accept() → UI 갱신
```

### Foreground 복귀

CloudKit 이벤트(`didReceiveRemoteChanges` / `didFinishCloudImport`)가 Items.swift의 debounced subscription(Path-B)을 통해 자동으로 데이터를 갱신하므로 `sceneDidBecomeActive`에서 중복 호출하지 않음.

```text
CloudKit Import/RemoteChange 발생
    ↓
Path-B: Items.swift debounce(2s)
    ↓
setUpUserCollection() → BehaviorRelay.accept() → UI 자동 갱신
```

## iCloud Account Handling

앱 시작 시 `CKContainer.accountStatus()`를 확인하고, `CKAccountChanged` 알림을 감시.

| 상태 | 동작 |
|------|------|
| `.available` | 정상 동기화 |
| `.noAccount` | Alert: "iCloud에 로그인되어 있지 않습니다" |
| `.restricted` | Alert: "iCloud 접근이 제한되어 있습니다" |
| `.temporarilyUnavailable` | Alert: "iCloud를 일시적으로 사용할 수 없습니다" |

## Error Handling

`NSPersistentCloudKitContainer.eventChangedNotification`에서 에러를 파싱:

| CKError | 동작 |
|---------|------|
| `.quotaExceeded` | Alert: "iCloud 저장 공간이 가득 찼습니다" |
| `.notAuthenticated` | Alert: "iCloud에 로그인되어 있지 않습니다" |
| `.networkFailure` / `.networkUnavailable` | 로그 기록 (자동 재시도 대기) |
| 기타 | `os_log(.error)` 기록 |

## Conflict Resolution

**Merge Policy**: `NSMergeByPropertyObjectTrumpMergePolicy`

- **속성(property) 단위** 병합: 서로 다른 속성 수정 시 양쪽 모두 반영
- **동일 속성** 충돌 시: 메모리(in-memory) 객체가 우선

## Toast UI (ToastManager)

`ToastManager.shared` — 전용 UIWindow(`windowLevel = .statusBar + 1`) 위에 토스트 표시.
어떤 화면(alert, modal 포함) 위에서든 항상 보이며, `isUserInteractionEnabled = false`로 터치 이벤트 통과.

- **표시 조건**: CloudKit Import 시작 시 (`incrementAndShow`)
- **해제 조건**: 모든 Import 완료 시 (`decrementAndDismiss`, 레퍼런스 카운팅)
- **타임아웃**: 60초 후 자동 dismiss
- **백그라운드 전환 시**: `dismiss()` → 즉시 해제 + 카운터 초기화 + 윈도우 해제

## Fresh Install Flow

신규 설치 시 CloudKit Import를 기다려 기존 iCloud 데이터를 수신한 후 앱을 시작:

```text
SceneDelegate.scene(_:willConnectTo:)
    ↓
isFreshInstall() == true
    ↓
markWaitingForFirstImport()  ← UC 생성 억제 플래그
    ↓
CloudSyncSplashViewController 표시
    ↓
waitForCloudKitImport(timeout: 10)
    ├── import-arrived → setupApp()
    ├── no-icloud → setupApp()
    └── timeout → setupApp()
```

## UC Duplication Prevention

**문제**: 신규 설치 시 로컬 UC 생성 → CloudKit Import로 기존 UC 도착 → UC 2개 존재 (영구 중복)

**해결**: `isWaitingForFirstImport` 플래그

1. 신규 설치 감지 시 `markWaitingForFirstImport()` 호출
2. `getUserCollection()`에서 UC 미존재 + 플래그 ON → `.notFound` throw (새 UC 생성 억제)
3. CloudKit Import 완료 시 플래그 자동 해제 → 이후 정상 동작
4. 모든 Storage 호출은 `.notFound` 에러를 graceful하게 처리 (`try?` → nil, do-catch → debugPrint)

**기존 중복 정리**: `consolidateUserCollections()` — 앱 시작/Import 완료 시 자동 실행:
- UC가 2개 이상이면 관계(relationships)가 가장 많은 UC 보존
- 나머지 UC의 자식 엔티티를 보존 UC로 `reassignRelationships`
- 고아 UC 삭제 → CloudKit Export로 iCloud에서도 정리

## Migration (기존 데이터 → CloudKit)

`migrateExistingDataToCloudKit()` — 일회성 마이그레이션:

1. `UserDefaults` 플래그로 실행 여부 확인
2. 모든 Entity의 속성을 한 번 터치하여 CloudKit Export 트리거
3. `try context.save()` 성공 시에만 플래그 설정 (원자성 보장)
4. 실패 시 다음 앱 실행에서 재시도

## Persistent History

- `NSPersistentHistoryTrackingKey` 활성화 (CloudKit 필수)
- 앱 시작 시 `cleanupPersistentHistory()` 호출 → 7일 이전 기록 삭제
- DB 비대화 방지

## Background Task

- `sceneDidEnterBackground`에서 `beginBackgroundTask` 호출 (30초)
- CloudKit 동기화 작업이 완료될 시간 확보

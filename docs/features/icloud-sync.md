# iCloud Sync (CloudKit)

## Overview

`NSPersistentCloudKitContainer`를 사용하여 여러 기기 간 수집 기록을 자동 동기화.
사용자 개입 없이 백그라운드에서 동작하며, Import 시 토스트 알림으로 상태를 안내.

## Architecture

```
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
| `CoreDataStorage.swift` | `NSPersistentCloudKitContainer` 설정, CloudKit 이벤트 감지, iCloud 계정 확인, Persistent History 정리 |
| `SceneDelegate.swift` | 토스트 표시/해제, iCloud 계정 알림, sync 에러 알림, foreground 복귀 시 데이터 갱신 |
| `Items.swift` | `didReceiveRemoteChanges` 구독 (debounce 500ms) → `setUpUserCollection()`, `refreshUserCollection()` |
| `ToastView.swift` | Import 상태 토스트 UI (ActivityIndicator + Label, slide 애니메이션) |

## Data Sync Flow

### Export (로컬 저장 → CloudKit)

```
User taps "collect item"
    ↓
CoreDataItemsStorage.update() → context.saveContext()
    ↓
NSPersistentCloudKitContainer 자동 Export (1-5초)
    ↓
CloudKit Server에 반영
```

### Import (CloudKit → 다른 기기)

```
CloudKit Silent Push 수신
    ↓
NSPersistentCloudKitContainer 자동 Import
    ↓
CoreDataStorage.handleCloudKitEvent() → didStartCloudImport 알림
    ↓
SceneDelegate → ToastView 표시 ("iCloud를 통해 수집 기록을 불러오는 중입니다.")
    ↓
Import 완료 → didFinishCloudImport 알림 → 토스트 dismiss
    ↓
NSPersistentStoreRemoteChange 알림
    ↓
Items.setUpUserCollection() → BehaviorRelay.accept() → UI 갱신
```

### Foreground 복귀

```
sceneDidBecomeActive
    ↓
Items.shared.refreshUserCollection()
    ↓
CoreData에서 최신 데이터 re-fetch (백그라운드에서 놓친 변경 보완)
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

## Toast UI

- **표시 조건**: CloudKit Import 시작 시
- **해제 조건**: 모든 Import 완료 시 (카운터 기반)
- **타임아웃**: 60초 후 자동 dismiss
- **백그라운드 전환 시**: 즉시 dismiss + 카운터 초기화

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

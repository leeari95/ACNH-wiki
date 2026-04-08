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
| `CoreDataStorage.swift` | `NSPersistentCloudKitContainer` 설정, CloudKit 이벤트 감지, iCloud 계정 확인, UC 중복 방지, 기존 유저 보호, 동기화 상태 조회, Persistent History 정리 |
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
CoreDataStorage.handleCloudKitEvent() → Import 완료
    ↓
hasImportedChanges() → Persistent History에서 CloudKit 트랜잭션 확인
    ↓
didFinishCloudImport 알림 (hasChanges: true/false)
    ↓
hasChanges == true → SceneDelegate → ToastManager.show(timeout: 3)
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
| Export 134301 (merge error) | `retryExportAfterMergeError()` — 최대 3회 지수 백오프 재시도 (5s, 10s, 15s) |
| Change Token Expired (CKError 21) | sync reset 감지 → orphan cleanup/UC 생성 억제 (아래 참조) |
| 기타 | `os_log(.error)` 기록 |

### Change Token Expired 대응

`NSCloudKitMirroringDelegate`가 Change Token Expired를 감지하면 내부 상태를 리셋하고 Setup → Export → Import 사이클을 재실행함.
이때 손상된 로컬 데이터가 Export되면 iCloud 원본까지 오염될 수 있으므로, sync reset 기간 동안 모든 cleanup과 UC 생성을 억제.

- `NSCloudKitMirroringDelegateWillResetSyncNotificationName` 감지 → `isSyncResetInProgress = true`
- 다음 Import 완료 시 자동 해제

## Conflict Resolution

**Merge Policy**: `NSMergeByPropertyObjectTrumpMergePolicy`

- **속성(property) 단위** 병합: 서로 다른 속성 수정 시 양쪽 모두 반영
- **동일 속성** 충돌 시: 메모리(in-memory) 객체가 우선

## Toast UI (ToastManager)

`ToastManager.shared` — 전용 UIWindow(`windowLevel = .statusBar + 1`) 위에 토스트 표시.
어떤 화면(alert, modal 포함) 위에서든 항상 보이며, `isUserInteractionEnabled = false`로 터치 이벤트 통과.

- **표시 조건**: Import 완료 시 Persistent History에 실제 CloudKit 데이터 변경이 있을 때만 (`hasImportedChanges()` → `author != nil` + `changes.isEmpty == false`)
- **해제 조건**: 3초 자동 dismiss (`show(timeout: 3)`)
- **백그라운드 전환 시**: `dismiss()` → 즉시 해제 + 윈도우 해제

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
                        ↓
              setupApp() → clearWaitingForFirstImport()
              (모든 경로에서 플래그 해제 보장)
```

## UC Duplication Prevention

**문제**: 신규 설치 시 로컬 UC 생성 → CloudKit Import로 기존 UC 도착 → UC 2개 존재 (영구 중복)

**해결**: 다중 억제 플래그 + 기존 유저 보호

`getUserCollection()`에서 UC가 없을 때 새 UC 생성을 억제하는 5가지 조건:

1. `isWaitingForFirstImport` — 신규 설치 시 Import 완료 전
2. `isImportInProgress` — Import가 진행 중 (timeout 후에도 import가 끝나지 않은 경우)
3. `isSyncResetInProgress` — Change Token Expired 후 re-import 대기
4. `_firstImportCompletedAt` grace period — 첫 Import 완료 후 120초간 UC 생성 유예
5. `hasEverHadUserCollection` — 기존 유저 보호 (아래 참조)

모든 Storage 호출은 `.notFound` 에러를 graceful하게 처리 (`try?` → nil, do-catch → `os_log`).
Import 완료 후 Path-B(`setUpUserCollection`)가 재실행되어 데이터가 정상 로드됨.

### Known User Protection (`hasEverHadUserCollection`)

**문제**: 앱 업데이트/iCloud 재로그인 시 `NSPersistentCloudKitContainer`가 CloudKit 미러를 재구성하면서 로컬 UC가 일시적으로 0개가 될 수 있음. 이때 빈 UC를 자동 생성하면 CloudKit에 빈 데이터가 Export되어 기존 클라우드 데이터가 오염됨.

**해결**: `UserDefaults` 기반 `hasEverHadUserCollection` 플래그 (메모리 캐싱, 변경 시에만 write-through):
- UC를 한 번이라도 성공적으로 fetch하면 `true`로 기록
- 이후 UC가 0개여도 빈 UC를 생성하지 않고 `.notFound`를 throw
- CloudKit re-import이 완료되면 정상 복구됨
- `performCloudKitRecovery()`에서도 플래그 유지 (복구 = 기존 유저)

**`shouldSuppressDataCreation` 통합 프로퍼티**: DailyTask 등 외부 Storage에서도 기본값 생성 억제 판단에 사용:
- `isWaitingForFirstImport || isImportInProgress || isSyncResetInProgress` 중 하나라도 true
- `isWithinGracePeriod` — 첫 Import 완료 후 `gracePeriodSeconds` (120초) 내
- 주의: `hasEverHadUserCollection`은 포함하지 않음 — `getUserCollection()`에서만 사용 (포함 시 DailyTask 자동 생성 영구 차단)

**기존 중복 정리**: `consolidateUserCollections()` — 앱 시작/Import 완료 시 자동 실행 (5초 지연, DispatchWorkItem으로 중복 방지):
- UC가 2개 이상이면 관계(relationships)가 가장 많은 UC 보존
- 나머지 UC의 자식 엔티티를 보존 UC로 `reassignRelationships`
- 고아 UC 삭제 → CloudKit Export로 iCloud에서도 정리

**Orphan Cleanup 안전장치** (`cleanupOrphanedEntities()`):
- Import 또는 sync reset 진행 중에는 실행하지 않음 (relationship이 아직 해소되지 않았을 수 있음)
- UC가 0개이면 실행하지 않음 (orphan 판단 기준 자체 없음)
- 전체 레코드가 모두 orphan이면 삭제하지 않음 (데이터 유실 방지)
- Count-first 최적화: 삭제 전 수량만 확인하여 불필요한 객체 로딩 방지

**진단 로그**: `logSyncDiagnostics(phase:)` — UC 중복 감지 시에만 상세 진단 출력:
- Entity별 카운트 요약은 항상 출력
- UC가 2개 이상일 때만 각 UC의 관계 수, objectID 등 상세 정보 로깅
- 불필요한 ItemEntity 전체 스캔 없음 (성능 최적화)

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
- expiration handler와 타이머 양쪽에서 idempotent하게 종료 (이중 호출 방지)

## Data Recovery (TEMPORARY)

설정 화면에서 "iCloud에서 데이터 복구" 기능 제공. 안정화 후 제거 예정.

**동작 원리**:
1. iCloud 계정 확인 → store coordinator에서 기존 store 분리
2. SQLite 파일 (.sqlite, -shm, -wal) + ckAssets 폴더 삭제
3. 앱 종료 (`exit(0)`) → 재시작 시 `loadPersistentStores`가 빈 store 생성
4. `NSPersistentCloudKitContainer`가 CloudKit에서 전체 데이터 자동 import

**관련 파일** (모두 `// TEMPORARY: Recovery` 주석):
- `CoreDataStorage.performCloudKitRecovery()`, `RecoveryError`
- `AppSettingReactor` — `.recoverFromCloud` Action, `.setRecoveryInProgress` Mutation
- `AppSettingView` — 복구 버튼 + ActivityIndicator
- `DashboardCoordinator.showRecoveryResultAlert()`
- `Localizable.strings` (ko/en) — 복구 관련 문자열 6개

## Sync Status Display

설정 화면에서 사용자가 iCloud 동기화 상태를 확인할 수 있는 정보 표시:

- **로컬 레코드 수**: UC 존재 여부 + 총 레코드 수 (Items, Tasks, Villagers, Houses)
- **마지막 동기화 시각**: Import/Export 중 가장 최근 성공 시각 (상대 시간 표시)
- **동기화 진행 중**: Import 또는 sync reset 진행 시 "동기화 중..." 표시
- **데이터 대기 중**: UC 미존재 시 "iCloud 데이터 대기 중..." 표시

**관련 파일**:
- `CoreDataStorage.fetchSyncStatus()`, `SyncStatusInfo`, `entityCounts(in:)` — 상태 조회 (logSyncDiagnostics와 공용)
- `CoreDataStorage.lastSuccessfulImportDate/ExportDate` — 성공 시각 추적
- `AppSettingReactor` — `.loadSyncStatus` Action, `.setSyncStatus` Mutation
- `AppSettingView` — `syncStatusLabel` + `updateSyncStatusLabel()`
- `DateFormatters.syncRelativeDate` — 상대 시간 포맷터 캐싱
- `Localizable.strings` (ko/en) — 동기화 상태 문자열 5개

## Error Logging

모든 Storage 클래스의 에러 로깅이 `debugPrint()` (Release 빌드에서 무시됨)에서 `os_log(.error)` (Release에서도 기록)로 강화됨.
Console.app 또는 Xcode에서 `CoreDataStorage`, `ItemsStorage`, `DailyTaskStorage` 등으로 필터하여 프로덕션 에러 추적 가능.

# iCloud Sync (CloudKit)

## Overview

`NSPersistentCloudKitContainer`를 사용하여 여러 기기 간 수집 기록을 자동 동기화.
사용자 개입 없이 백그라운드에서 동작하며, Import 시 토스트 알림으로 상태를 안내.

> **3.2.4 변경사항**: 자동 consolidation/orphan cleanup이 사용자 로컬 데이터를 삭제하는 버그
> 때문에 **자동 호출을 모두 제거**했습니다. 중복 정리 및 복원은 설정 화면에서 사용자가 명시적으로
> 트리거해야 합니다. 상세는 아래 "Manual Consolidation" / "Data Recovery" 섹션 참조.
> (중기 계획 — `docs/plans/local-backup-split.md` 참조: 로컬/백업 store 분리 아키텍처로 이관 예정)
>
> **sync reset의 트리거 제거**: 앱 시작마다 7일 이전 persistent history를 삭제하던 코드가
> CloudKit 미러의 history token을 만료(134301)시켜 sync reset → 로컬 purge를 유발하고 있었습니다.
> history 삭제를 제거했고, reset 이후 부분 re-import 상태가 로컬 안전 스냅샷을 덮어쓰지 않도록
> reset hold를 추가했습니다. 상세는 "Persistent History" / "Sync Reset Hold" 섹션 참조.

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
| `CoreDataStorage.swift` | `NSPersistentCloudKitContainer` 설정, CloudKit 이벤트 감지, iCloud 계정 확인, UC 중복 방지, 기존 유저 보호, 동기화 상태 조회, Persistent History 보존(삭제 금지) |
| `SceneDelegate.swift` | 신규 설치 감지 + CloudKit Import 대기, iCloud 계정/에러 알림, ToastManager 연동 |
| `Items.swift` | `didReceiveRemoteChanges` 구독 (debounce 2s) → `setUpUserCollection()` |
| `ToastManager.swift` | 전용 UIWindow 기반 토스트 매니저. 레퍼런스 카운팅, 타임아웃, 백그라운드 dismiss |
| `ToastView.swift` | Import 상태 토스트 UI (캡슐형 디자인, ActivityIndicator + Label, slide 애니메이션) |
| `CloudSyncSplashViewController.swift` | 신규 설치 시 CloudKit Import 대기 스플래시 화면 |
| `SafetySnapshotService.swift` | CloudKit purge/reset에 대비한 로컬 안전 스냅샷 작성, sync reset hold, 수동 복원 |

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
| Cocoa 134301 `NSPersistentHistoryTokenExpiredError` | reason `history_token_expired`로 telemetry 분류. 곧 sync reset(HistoryExpired) → 로컬 purge로 이어지는 신호 — 아래 "Persistent History" 참조 |
| 기타 Export 실패 | `retryExportAfterMergeError()` — 최대 3회 지수 백오프 재시도 (5s, 10s, 15s) |
| Change Token Expired (CKError 21) | sync reset 감지 → orphan cleanup/UC 생성 억제 (아래 참조) |
| 기타 | `os_log(.error)` 기록 + 보호 모드 안내 (아래) |

**Sync 보호 모드 안내**: sync 실패가 반복되어 UC가 없는데 생성이 억제된 상태
(`isAwaitingCloudDataWithoutCollection == true`)라면, `SceneDelegate.handleCloudSyncError`가
세션당 한 번 "데이터 보호를 위해 새 데이터 생성을 보류 중" Alert를 표시한다.
사용자가 조용한 빈 컬렉션 화면에 갇히는 것을 방지하기 위한 안내.

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
    ├── import-arrived → setupApp() → completeFirstImportWait(.importArrived)
    ├── no-icloud      → setupApp() → completeFirstImportWait(.noICloud)
    └── timeout        → setupApp() → completeFirstImportWait(.timeout)
```

`timeout`은 "CloudKit에 데이터가 없다"는 의미가 아니라 "아직 확인하지 못했다"는 의미로 처리한다.
따라서 앱은 열리지만 `isFirstImportTimedOut`을 유지하여 빈 `UserCollectionEntity`와 기본 DailyTask 생성을 계속 억제한다.
이후 Import 이벤트가 실제로 성공하면 `handleCloudKitEvent()`가 timeout 상태를 해제하고 Path-B가 데이터를 다시 로드한다.
Import가 에러로 종료되면 CloudKit 데이터 유무가 여전히 불명확하므로 timeout/reset 억제 상태를 유지한다.
단, timeout 콜백보다 먼저 Import 성공 이벤트가 이미 관측된 경우에는 timeout 상태를 남기지 않는다.

계정 없는 회귀 테스트는 `CoreDataStorageICloudResetTests`에서 관리한다. 이 테스트는 실제 iCloud 로그인 없이
로컬 store와 sync 플래그를 조작한 뒤 앱 초기화 경로의 `CoreDataDailyTaskStorage.fetchTasks()`까지 실행하여,
애매한 동기화 상태에서 빈 `UserCollectionEntity`나 기본 `DailyTaskEntity`가 생성되면 실패한다.

## UC Duplication Prevention

**문제**: 신규 설치 시 로컬 UC 생성 → CloudKit Import로 기존 UC 도착 → UC 2개 존재 (영구 중복)

**해결**: 다중 억제 플래그 + 기존 유저 보호

`getUserCollection()`에서 UC가 없을 때 새 UC 생성을 억제하는 6가지 조건:

1. `isWaitingForFirstImport` — 신규 설치 시 Import 완료 전
2. `isImportInProgress` — Import가 진행 중 (timeout 후에도 import가 끝나지 않은 경우)
3. `isSyncResetInProgress` — Change Token Expired 후 re-import 대기
4. `isFirstImportTimedOut` — 첫 Import 대기가 timeout됐지만 CloudKit 데이터 유무가 아직 불명확
5. `_firstImportCompletedAt` grace period — 첫 Import 완료 후 120초간 UC 생성 유예
6. `hasEverHadUserCollection` — 기존 유저 보호 (아래 참조)

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
- `isWaitingForFirstImport || isImportInProgress || isSyncResetInProgress || isFirstImportTimedOut` 중 하나라도 true
- `isWithinGracePeriod` — 첫 Import 완료 후 `gracePeriodSeconds` (120초) 내
- 주의: `hasEverHadUserCollection`은 포함하지 않음 — `getUserCollection()`에서만 사용 (포함 시 DailyTask 자동 생성 영구 차단)

**기존 중복 정리**: `consolidateUserCollectionsManually()` — 설정 화면에서 사용자가 명시적으로 실행:
- UC가 2개 이상이면 관계(relationships)가 가장 많은 UC 보존
- 나머지 UC의 자식 엔티티를 보존 UC로 `reassignRelationships`
- 고아 UC 삭제 → CloudKit Export로 iCloud에서도 정리

**Orphan Cleanup 안전장치** (`cleanupOrphanedEntities()`):
- Import 또는 sync reset 진행 중에는 실행하지 않음 (relationship이 아직 해소되지 않았을 수 있음)
- 첫 Import 완료 후 grace period(120초) 내에도 실행하지 않음 — CloudKit이 relationship을
  비동기로 해소하는 동안 일시적 orphan을 실제 orphan으로 오판해 삭제하는 것을 방지
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
- **앱에서 history를 삭제하지 않는다** (`deleteHistory(before:)` 금지)
- `initializeHistoryToken()`은 전체 트랜잭션을 fetch하지 않고 `currentPersistentHistoryToken(fromStores:)`로 현재 토큰만 조회한다

### 왜 삭제하면 안 되는가 (3.2.0~3.2.4 "데이터 초기화"의 직접 원인)

`NSCloudKitMirroringDelegate`는 persistent history로 "마지막 export 이후의 로컬 변경"을 추적한다.
미러가 아직 처리하지 않은 구간(또는 미러 토큰이 가리키는 트랜잭션)을 앱이 지우면:

```text
앱 시작 → deleteHistory(before: 7일 전)        ← 3.2.0(#156)~3.2.4의 SceneDelegate.setupApp()
    ↓
CloudKit Export 실패: Cocoa 134301 "Persistent History Token is expired"
    ↓
NSCloudKitMirroringDelegate.recoverFromError → WillResetSync (reason: HistoryExpired)
    ↓
로컬 store purge → CloudKit 전체 re-import
    ↓
re-import 실패/지연/부분 도착 시 로컬 데이터 소실 — export되지 못한 변경분은 iCloud에도 없어 영구 유실
```

- 7일 넘게 앱을 열지 않은 사용자(시즌 단위로 게임을 하는 사용자, 업데이트 후 오랜만에 실행하는 사용자)가
  다시 앱을 켜는 순간 재현된다. "업데이트 후 초기화", "어느 날 갑자기 사라짐" 제보 패턴과 일치.
- 3.2.0 이전에는 history 삭제가 없었고, 클레임은 3.2.0 이후 시작됨.
- Apple 엔지니어 가이드: history를 남겨두는 것은 일반적으로 문제가 없으며, 미러가 처리하기 전에 지우면 로컬 변경이 동기화되지 않는다.
  이 앱의 데이터 규모(수백~수천 레코드)에서는 history 증가가 실질적 부담이 아니다.
- 향후 정리가 꼭 필요해지면 "미러가 처리한 지점"을 확인할 수 있는 단일 gatekeeper 설계가 선행되어야 한다 (시간 기준 삭제 금지).

## Background Task

- `sceneDidEnterBackground`에서 `beginBackgroundTask` 호출 (30초)
- CloudKit 동기화 작업이 완료될 시간 확보
- expiration handler와 타이머 양쪽에서 idempotent하게 종료 (이중 호출 방지)

## Data Recovery (수동 복원)

설정 화면에서 "iCloud에서 복원 (로컬 데이터 덮어씀)" 기능 제공. 3.2.4부터 정식 기능으로 승격.
**파괴적 동작** — 2단 확인 Alert 후에만 실행됨.

**동작 원리**:
1. iCloud 계정 확인 → store coordinator에서 기존 store 분리
2. SQLite 파일 (.sqlite, -shm, -wal) + ckAssets 폴더 삭제
3. `recoveryInitiatedAt` 타임스탬프 기록 (10분 grace period)
4. 앱 종료 (`exit(0)`) → 재시작 시 `loadPersistentStores`가 빈 store 생성
5. `NSPersistentCloudKitContainer`가 CloudKit에서 전체 데이터 자동 import

**Recovery Grace Period (10분)**:
- 재시작 후 CloudKit import가 지연되거나 실패한 상태를 UI/로그에서 구분하기 위한 표시용 플래그
- `getUserCollection()`은 grace 기간 안에서도 `hasEverHadUserCollection == true`이면 UC 신규 생성을 막음
- 빈 UC를 만들면 CloudKit으로 빈 데이터가 Export되어 기존 iCloud 데이터를 오염시킬 수 있으므로 허용하지 않음
- 10분 경과 또는 정상 import 완료 시 플래그 자동 정리

**관련 파일**:
- `CoreDataStorage.performCloudKitRecovery()`, `RecoveryError`, `markRecoveryInitiated`, `isWithinRecoveryGracePeriod`
- `AppSettingReactor` — `.recoverFromCloud` Action (2단 확인), `.setRecoveryInProgress` Mutation
- `AppSettingView` — 복구 버튼 + ActivityIndicator
- `DashboardCoordinator.showRecoveryResultAlert()`
- `Localizable.strings` (ko/en) — 복구 관련 문자열

### Local Safety Snapshot

`SafetySnapshotService`는 UC 그래프를 `local_safety_snapshot.plist`로 유지한다.
CloudKit import, remote change, sync reset 직전에는 최신 로컬 상태를 스냅샷으로 남겨 iOS가 Core Data store를 purge해도 사용자가 수동 복원할 수 있게 한다.

- 스냅샷 파일은 첫 잠금 해제 후 백그라운드 CloudKit flush에서도 갱신될 수 있도록 `completeUntilFirstUserAuthentication` 보호 등급으로 저장한다.
- 파일은 기기/iCloud 백업에서 제외하여 Core Data 원본과 별도로 장기 보관되지 않게 한다.
- 복원은 `wipeExistingCollection → snapshot.apply → context.save()`를 단일 context rollback 경계에 묶는다. 중간 실패 시 기존 로컬 컬렉션 삭제가 저장되지 않는다.
- debounce용 `pendingWorkItem`은 CoreData 저장 알림(임의 스레드)·main 스레드·sync-reset 알림이
  동시에 접근하므로 `OSAllocatedUnfairLock`으로 보호하고, `flushNow()`는 debounce 쓰기와
  파일 I/O가 겹치지 않도록 전용 queue에서 동기 실행한다.

#### Sync Reset Hold (부분 re-import로 백업이 덮어써지는 문제 방지)

sync reset 뒤 re-import가 일부만 도착한 상태도 "Import 성공"으로 끝날 수 있다. 이전에는 이 상태가
30초 debounce 후 스냅샷으로 저장되어 **reset 이전의 정상 백업을 덮어썼고**, UC가 1개라도 있으면
복원 프롬프트도 뜨지 않아 마지막 안전망이 사라졌다.

- `willReset` 수신 시 `handleSyncResetImminent()`가 같은 queue에서 flush → `establishResetHold()`를 동기 실행.
  그 시점 백업의 항목 수를 `SafetySnapshot_resetHoldChildCount`(UserDefaults)에 기록한다.
  이미 hold 중이면 더 큰 값을 유지 (부분 상태에서 reset이 반복돼도 원래 기준 보존).
- hold 중에는 현재 항목 수가 hold보다 적은 스냅샷 쓰기를 건너뛴다 (`🛟 SafetySnapshot skipped: ... (holding)`).
- 해제 조건:
  - 현재 데이터가 hold 이상으로 회복되어 스냅샷이 정상 기록됨 (자동)
  - 로컬 백업 복원 성공 (`restore()`)
  - 사용자가 프롬프트에서 "현재 데이터 유지" 선택
  - 의도적 데이터 초기화 (`CoreDataUserInfoStorage.resetUserInfo()`)
- 앱 시작 프롬프트(`SceneDelegate.offerSafetySnapshotRestoreIfNeeded`) 조건:
  1. 기존 유저인데 UC가 없음 (`hasEverHadUserCollection && isFreshInstall`) — 기존 동작
  2. hold 중이고 현재 항목 수 < hold (`currentChildCountIfBelowResetHold() != nil`) — 부분 re-import
  - 2번(부분 re-import)일 때만 "현재 데이터 유지" 버튼을 추가로 노출한다. UC가 통째로 없는 1번에서는 유지할
    현재 데이터가 없으므로 노출하지 않는다 (백업 보존 유지).
  - 부분 re-import 상태의 복원은 기존 로컬 복원과 같이 **현재 데이터를 백업으로 교체**한다 (병합 아님).
    백업 이후 다른 기기에서 추가한 기록이 사라질 수 있음을 프롬프트 문구에 명시한다.
- 보존할 백업 파일이 없으면(삭제 등) hold는 쓰기를 막지 않고, 다음 기록 시 해제된다.
- 트레이드오프: hold 중에는 백업이 reset 시점 상태로 고정되어, 그 사이 편집은 회복/명시적 결정 전까지 백업에 반영되지 않는다.

## Manual Consolidation (중복/고아 데이터 정리)

**3.2.4부터 자동 consolidation 제거됨** — 로컬 데이터가 의도치 않게 삭제되는 버그로 인해,
사용자가 설정에서 "중복/고아 데이터 정리" 버튼을 직접 눌렀을 때만 실행.

**제거된 자동 호출부**:
- ~~`CoreDataStorage.handleCloudKitEvent()` Import 완료 후 5초 지연~~
- ~~`SceneDelegate.setupApp()` 앱 시작 시~~

**수동 호출**:
- `CoreDataStorage.consolidateUserCollectionsManually(completion:)` — 설정 버튼에서만 호출
- `consolidateUserCollections()` (기존 함수)는 유지하되 자동 호출처 없음

**삭제 시 로깅**:
- `cleanupOrphanedEntities` 내부 삭제 직전 `os_log(.error)`로 대상 수량 기록 (Release에서도 추적 가능)
- Console.app에서 `"🔧 Orphan cleanup"` 필터로 실제 삭제 이력 감사 가능

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

## Remote Telemetry (Firebase)

3.2.0 이후 "로컬 데이터가 초기화되었다"는 클레임을 원격에서 추적하기 위해, `Utility/Log.swift`에서
Crashlytics(세션 breadcrumb + custom keys + 비치명 에러)와 Analytics(집계 이벤트/클릭)를 통합 래핑.

### Logging API

모든 레벨(`verbose` ~ `error`)은 **3-way fan-out**: `os_log` + Crashlytics breadcrumb + Analytics 이벤트.
에러/크래시 없이도 Analytics 콘솔에서 로그가 보이며, 문제 발생 시엔 Crashlytics breadcrumb으로 세션 맥락이 함께 업로드됨.

| 호출 | 용도 | Analytics 이벤트명 |
|------|------|-------------------|
| `Log.verbose(_:)` | 상세 추적 | `log_verbose` |
| `Log.debug(_:)` | 디버그 흐름 | `log_debug` |
| `Log.info(_:)` | 일반 흐름, 결정 지점 | `log_info` |
| `Log.warning(_:)` | 주의 상태 | `log_warning` |
| `Log.error(name:reason:userInfo:)` | **비치명 에러 업로드** | `log_error` + Crashlytics `recordError` |
| `Log.event(_:parameters:)` | 구조화된 집계 이벤트 | (Event enum) |
| `Log.click(_:parameters:)` | 사용자 탭 추적 | `select_content` |
| `Log.setContext(_:_:)` | 커스텀 키 단건 설정 | — (Crashlytics 전용) |
| `Log.snapshot(...)` | 엔티티 카운트/플래그 일괄 전송 | — (Crashlytics 전용) |

**메시지 길이**: Analytics 파라미터 제한(100자)에 맞춰 자동 잘림.

### Analytics Events (집계)

| Event | 발생 지점 |
|-------|-----------|
| `sync_recovery_triggered` | `performCloudKitRecovery` 성공 — 사용자가 설정에서 복원 실행 |
| `sync_orphan_cleanup` | `cleanupOrphanedEntities`가 실제로 레코드 삭제 (entity/count 파라미터) |
| `sync_uc_consolidated` | 중복 UC가 통합됨 (uc_total/kept_relationships) |
| `sync_uc_created` | 새 UC 생성 (path: fresh_user) |
| `sync_uc_creation_suppressed` | UC 생성이 억제됨 (reason: sync_in_progress \| grace_period) |
| `sync_token_expired` | `NSCloudKitMirroringDelegateWillReset` 감지 |
| `sync_user_collection_missing` | **핵심 증상**: hasEverHadUC=true인데 UC=0 |
| `sync_cloud_failed` | CloudKit Export/Import 실패 (reason/code). reason `history_token_expired` = 134301 (sync reset 전조) |

### Crashlytics Custom Keys (세션 스냅샷)

`logSyncDiagnostics(phase:throttled:)` 호출 시 os_log 진단 + `Log.snapshot` 갱신을 한 번의 background fetch로 수행.
Import 종료, UC missing 시점에 자동 전송. UC missing처럼 즉시 컨텍스트가 필요한
경우 `throttled: false` 로 호출하여 5초 throttle을 우회.

- `sync_uc_count` / `sync_item_count` / `sync_task_count` / `sync_villager_count`
- `sync_has_ever_had_uc` / `sync_is_fresh_install`
- `sync_waiting_first_import` / `sync_import_in_progress` / `sync_reset_in_progress`
- `sync_within_recovery_grace`
- `sync_last_import_at` / `sync_last_export_at` (epoch seconds)
- `sync_app_version`

### 비치명 에러 (Crashlytics `recordError`)

세션 breadcrumb과 custom keys를 포함한 상세 컨텍스트를 Firebase Crashlytics에 업로드:

- `Log.UserCollectionMissing` — hasEverHadUC=true + UC=0 관측
- `Log.OrphanCleanupDelete` — 실제 orphan 삭제 발생 (감사 로그)

### 조사 가이드

사용자 클레임 접수 시:

1. Firebase Crashlytics → Non-fatal issues → `UserCollectionMissing` 필터
2. 해당 세션의 breadcrumb(`log()` 문자열)으로 이벤트 순서 재구성
3. custom keys로 그 순간의 엔티티 수/플래그 상태 확인
4. Analytics → `sync_user_collection_missing` 분포로 버전/일자별 발생 빈도 확인

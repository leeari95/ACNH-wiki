# Stage 2 설계안: Local/Backup Store 분리 아키텍처

> **상태**: 설계 리뷰 중 (구현 전 팀 리뷰 필수)
> **목표**: iCloud 자동 복원으로 인한 로컬 데이터 손실 버그를 구조적으로 제거
> **전제**: Stage 1 핫픽스(`3.2.4`)로 자동 삭제 경로는 이미 차단된 상태

## 1. 배경

현재 앱은 단일 `NSPersistentCloudKitContainer`에서 로컬 CoreData와 CloudKit 미러가 한 몸이다.
CloudKit Import가 발생하면 로컬 객체 그래프가 원격 상태로 merge되며, relationship 해소 과정에서
orphan으로 보이는 child entity가 자동 cleanup되어 사용자 데이터가 손실되는 사례가 반복 보고됨.

Stage 1에서 자동 삭제 경로를 모두 끊었지만, **자동 Import 자체가 로컬을 touch하는 구조**는 여전히
잠재 위험. Stage 2는 이 근본을 분리한다.

## 2. 목표 아키텍처

```
┌────────────────────────────┐          ┌─────────────────────────────────┐
│  LocalStore                │          │  BackupStore                    │
│  NSPersistentContainer     │          │  NSPersistentCloudKitContainer  │
│  (CloudKit 미러 없음)       │          │  (CloudKit 미러됨)              │
│                            │          │                                 │
│  현행 모델 그대로:          │─serialize→│  단일 Entity:                    │
│  UserCollection, Item,     │          │  BackupSnapshotEntity {         │
│  DailyTask, Villager, …    │←deserial.─│    deviceId: String,            │
│                            │          │    version: Int,                │
│  앱의 모든 read/write 대상  │          │    createdAt: Date,             │
│                            │          │    payload: Data (JSON)         │
│                            │          │  }                              │
└────────────────────────────┘          └─────────────────────────────────┘
```

### 핵심 원칙
1. **LocalStore는 CloudKit을 모른다** — mirroring이 없으므로 자동 Import 자체가 존재하지 않음
2. **BackupStore는 "스냅샷 저장소"** — 앱 데이터의 직렬화된 최신 상태 1행(per device) 유지
3. **두 개의 별도 Container** — 1-container multi-description 방식은 CKMD_* 메타 충돌 리스크로 제외
4. **Restore는 항상 수동** — 사용자가 설정 버튼을 눌렀을 때만 BackupStore → LocalStore 적용

## 3. 데이터 플로우

### 자동 백업 (Export)
```
User edits data → LocalStore.save()
    ↓
NSManagedObjectContextDidSave 관찰 (debounce 10s)
    ↓
BackupService.createSnapshot()
    - LocalStore에서 모든 엔티티 fetch
    - Codable 구조체로 변환 → JSONEncoder
    - payload: Data
    ↓
BackupStore upsert:
    - fetch BackupSnapshotEntity where deviceId == self
    - 있으면 payload/version/createdAt 갱신, 없으면 insert
    - save()
    ↓
NSPersistentCloudKitContainer 자동 Export → CloudKit 반영
```

### 수동 복원 (Restore)
```
User taps "iCloud에서 복원" (2단 확인)
    ↓
RestoreService.restore()
    - BackupStore에서 최신 BackupSnapshotEntity fetch
      (여러 device의 snapshot 중 createdAt 최신)
    - payload Data → JSONDecoder → Codable 구조체
    ↓
LocalStore 완전 교체:
    - 기존 UC/자식 전부 delete
    - Codable 구조체 기반으로 재구성 (새 ObjectID)
    - save()
    ↓
Items.shared.setUpUserCollection() → UI 갱신
```

## 4. 데이터 모델

### LocalStore
- 현행 `.xcdatamodeld`를 **그대로 재사용**
- 모든 description에서 `cloudKitContainerOptions = nil`
- 기존 sqlite 파일은 **재사용 불가** (CKMD_* 잔재 위험) — 신규 파일에 export

### BackupStore (신규 `Backup.xcdatamodeld`)
```swift
entity BackupSnapshotEntity {
    deviceId: String   // UserDefaults UUID (identifierForVendor 금지 — 볼륨 마운트 시 변경됨)
    version: Int       // 스키마 버전 (decoder 호환성 판정)
    createdAt: Date    // 스냅샷 생성 시각
    payload: Data      // JSON 직렬화된 CollectionSnapshot
    deviceName: String // 사용자가 기기 식별용 (선택)
}
```

### CollectionSnapshot (Codable 직렬화 형식)
```swift
struct CollectionSnapshot: Codable {
    let version: Int
    let userInfo: UserInfoSnapshot
    let items: [ItemSnapshot]        // Transformable 14개 필드 → Codable
    let dailyTasks: [DailyTaskSnapshot]
    let villagersLike: [VillagerLikeSnapshot]
    let villagersHouse: [VillagerHouseSnapshot]
    let npcLike: [NPCLikeSnapshot]
    let variants: [VariantSnapshot]
}
```

**ItemEntity 직렬화 주의점**: 현재 Transformable 14개 (colors, concepts, keywords, recipe, variations,
translations 등)는 `NSSecureUnarchiveFromData`로 NSArray/NSDictionary 저장. Codable 변환 레이어를 추가하되,
**동일 필드의 원본 타입은 건드리지 않음** (LocalStore에서는 기존대로 동작).

## 5. Migration 전략

### 기존 유저 (3.2.x → 3.3.0)
1. 첫 실행 시 `NSPersistentCloudKitContainer` 한 번 더 기동 → CloudKit에서 legacy 데이터 마지막 import 시도 (최대 15초)
2. 기존 sqlite 내용을 **신규 LocalStore 파일에 export** (CoreData에서 CoreData로 복사 — 관계 포함)
3. Export 성공 후 현재 `BackupStore`에 최초 스냅샷 생성
4. 성공 시 `UserDefaults["migratedToLocalBackupSplit"] = true`
5. 기존 `CoreDataStorage.sqlite` 파일은 **삭제하지 않고 유지** (롤백 대비)
6. 다음 버전에서 legacy 파일 cleanup

### 신규 설치 (앱 최초 설치)
1. LocalStore 빈 상태로 시작
2. BackupStore에서 CloudKit import 10초 대기 (Splash 재사용)
3. Import 도착 & snapshot 존재 → "iCloud 백업 발견. 복원하시겠습니까?" 제안
4. 사용자 수락 시 RestoreService 실행
5. 거절 시 빈 LocalStore로 시작 (기존 자동 수신 동작과 UX 차이 — 온보딩 문구 명시)

### 여러 기기 운영
- 각 device가 자기 deviceId로 별도 snapshot row 생성
- 다른 기기의 변경을 보려면 수동 복원 필요
- **실시간 동기화 상실은 의도된 트레이드오프** — 설정 화면 문구를 "마지막 백업: HH:MM" 형태로 교체

## 6. Items.shared 영향

| 기존 | 신규 |
|------|------|
| `didReceiveRemoteChanges` / `didFinishCloudImport` 구독 → `setUpUserCollection()` | **제거** (LocalStore는 remote 이벤트 없음) |
| `sceneDidBecomeActive`에서 중복 호출 안 함 | 동일 |
| `setUpUserCollection()` 직접 호출 경로 | 동일 + `RestoreService` 완료 후 명시 호출 |

## 7. 테스트 전략 (필수 신설)

현재 프로젝트는 CoreData/CloudKit 관련 유닛 테스트가 **0건**. Stage 2는 다음 최소 테스트와 함께 간다:

1. **SnapshotCodec**: 모든 Entity → Codable round-trip (nil/빈 배열/Transformable 필드 포함 fixture)
2. **StoreMigrator**: legacy sqlite → LocalStore export 성공 케이스 + 중단 복구
3. **BackupService**: debounce 동작, 동일 deviceId upsert, 다른 deviceId 추가 insert
4. **RestoreService**: 기존 LocalStore 완전 교체 + UC 1개 보장 + 관계 복원
5. **통합**: 백업 → 로컬 wipe → 복원 → 원본과 동일한지 검증

## 8. 리스크 정리

| 리스크 | 가능성 | 영향 | 완화책 |
|-------|-------|------|-------|
| Migration 중 앱 크래시 → 데이터 분실 | 낮음 | 치명적 | 원본 sqlite 유지, 플래그 세팅은 성공 후에만 |
| CloudKit 1MB CKRecord 한도 초과 | 중간 | 동기화 실패 | Data 필드 ≥1MB는 자동 CKAsset (iOS가 처리) — 테스트로 검증 |
| 다기기 동시 편집 시 last-write-wins | 중간 | UX 악화 | 현재도 단일 snapshot이므로 "수동 복원" 원칙으로 명시 |
| deviceId 변경 (iOS 복구/TestFlight→App Store) | 낮음 | 중복 snapshot row | UserDefaults UUID 사용 (persistent), 중복 감지 시 오래된 row 정리 |
| Transformable → Codable 변환 오류 | 중간 | 스냅샷 손상 | version 필드로 스키마 호환성 판정, fallback decoder |
| 앱 first-launch 시 CloudKit 대기 UX 후퇴 | 확실 | UX | 온보딩 문구 업데이트 + "자동으로 복원할까요?" 제안 플로우 |

## 9. 구현 페이즈 (2주)

- **Day 1-2**: BackupStore 모델 + `BackupSnapshotEntity` + Codable Snapshot 구조체
- **Day 3-4**: `SnapshotCodec` (Entity ↔ Codable), round-trip 테스트
- **Day 5-6**: `BackupService` (debounce + upsert) + `RestoreService`
- **Day 7**: `StoreMigrator` (legacy sqlite → LocalStore export)
- **Day 8**: CloudKitContainer 2개로 기동, LocalStore는 `NSPersistentContainer`로 교체
- **Day 9**: `Items.shared` 구독 경로 제거, UI 문구 업데이트
- **Day 10**: 2단 복원 UI + 신규 설치 복원 제안 UI
- **Day 11-12**: QA (기존 유저 업데이트 시나리오, 신규 설치, 기기 전환, 오프라인)
- **Day 13-14**: 단계적 롤아웃 준비, 롤백 가이드 문서화

## 10. 결정 대기 항목

- [ ] LocalStore 파일명을 `Local.sqlite`로 신설할지, 기존 `CoreDataStorage.sqlite`를 그대로 쓰되 CloudKit 옵션만 제거할지 (safer: 신설)
- [ ] 스냅샷 버전 정책 — 매 save마다 version++ vs. 단일 row overwrite만
- [ ] 기기별 snapshot 수 상한 (예: 3개 초과 시 오래된 것 정리)
- [ ] 사용자가 "자동 백업 끄기" 옵션을 원할 경우 제공할지

## 11. 관련 문서

- [Stage 1 핫픽스 반영된 icloud-sync.md](../features/icloud-sync.md)
- [Coordinator 패턴](../patterns/coordinator-pattern.md)
- [데이터 흐름 (Items.shared)](../patterns/data-flow.md)

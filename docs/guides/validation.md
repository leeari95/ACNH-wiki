# Validation Scripts

아키텍처 경계와 코딩 규약을 자동 검증하는 스크립트 시스템.

## Quick Start

```bash
# 전체 검증 (아키텍처 + 패턴 + 문서)
make validate

# CI 전체 흐름 (린트 + 검증 + 빌드)
make ci
```

`make validate`는 내부적으로 `validate-arch`, `validate-patterns`, `validate-docs` 세 타겟을 순차 실행한다.

## validate-architecture.sh

**파일**: `scripts/validate-architecture.sh`

레이어 간 의존성 규칙을 검증한다. 상위 레이어가 하위 레이어만 참조하도록 강제한다.

### 아키텍처 레이어 (상위 -> 하위)

```
Presentation  → UI 레이어 (ViewControllers, Reactors, Views)
Utility       → 공유 유틸리티 (Presentation 제외 모두 import 가능)
Extension     → Swift 확장 (Presentation, CoreDataStorage import 금지)
CoreDataStorage → 영속성 레이어 (Presentation, Networking import 금지)
Networking    → API 레이어 (Presentation, CoreDataStorage, Utility import 금지)
Models        → 순수 도메인 모델 (Foundation / CoreFoundation만 허용)
```

### 4개 체크 항목

| Check | 설명 |
|-------|------|
| Check 1 | **Models 순수성** — `Models/*.swift`는 `Foundation`과 `CoreFoundation`만 import 가능 |
| Check 2 | **Networking 격리** — `Networking/`에서 Presentation, CoreDataStorage, Utility 타입 참조 금지 |
| Check 3 | **Presentation -> CoreDataStorage** — `Presentation/`에서 `CoreData*Storage` 구체 클래스 직접 참조 금지 (프로토콜 추상화 사용) |
| Check 4 | **역방향 의존성** — 하위 레이어(CoreDataStorage, Extension, Utility)가 상위 레이어(Presentation, Networking) import 금지 |

### Allowlist (기존 위반 13개 파일)

다음 파일들은 레거시 코드로, `CoreData*Storage` 구체 클래스를 기본 파라미터로 참조하고 있다. 리팩토링 예정이며 현재는 경고(warning)로 처리된다.

```
Presentation/Catalog/ViewModels/ItemDetailReactor.swift
Presentation/Catalog/ViewModels/ItemsReactor.swift
Presentation/Catalog/ViewModels/CatalogCellReactor.swift
Presentation/Dashboard/ViewModels/CustomTaskReactor.swift
Presentation/Dashboard/ViewModels/TodaysTasksSectionReactor.swift
Presentation/Dashboard/ViewModels/PreferencesReactor.swift
Presentation/Dashboard/ViewModels/AppSettingReactor.swift
Presentation/Dashboard/ViewModels/TasksEditReactor.swift
Presentation/Animals/ViewModels/VillagerDetailReactor.swift
Presentation/Animals/ViewModels/VillagersCellReactor.swift
Presentation/Animals/ViewModels/NPCDetailReactor.swift
Presentation/Animals/ViewModels/NPCCellReactor.swift
Presentation/Collection/ViewModels/CollectionReactor.swift
```

역방향 의존성 allowlist (1개 파일):

```
Utility/TurnipPriceCalculator.swift
```

### --strict 모드

```bash
bash scripts/validate-architecture.sh --strict
```

`--strict` 모드에서는 allowlist에 등록된 파일도 에러로 처리되어 빌드가 실패한다. 모든 레거시 위반을 수정한 후 CI에서 strict 모드 전환을 검토할 수 있다.

## validate-patterns.sh

**파일**: `scripts/validate-patterns.sh`

Presentation 레이어의 코딩 규약 준수 여부를 검증한다.

### 4개 체크 항목

| Check | 설명 |
|-------|------|
| Check 1 | **Reactor 패턴** — 모든 `*Reactor.swift` 파일에 `enum Action`, `enum Mutation`, `struct State`가 존재하는지 확인 |
| Check 2 | **Coordinator Route** — 모든 `*Coordinator.swift` 파일(AppCoordinator 제외)에 `enum Route`가 존재하는지 확인 |
| Check 3 | **디렉토리 구조** — 각 feature 디렉토리에 `Coordinator/`, `ViewControllers/`, `ViewModels/` 서브디렉토리 존재 확인 |
| Check 4 | **bind(to:)** — 모든 `*ViewController.swift` 파일에 `func bind(to` 메서드가 존재하는지 확인 |

### Allowlist (패턴 검증)

| 예외 | 사유 |
|------|------|
| `TurnipPrices/` | flat 구조 — 서브디렉토리 없이 단일 폴더로 구성 (Check 3 경고만 발생) |
| `MusicPlayer/` | Coordinator 없음 — `AppCoordinator`가 직접 관리 (Check 3 경고만 발생) |
| `IconChooserViewController.swift` | UI-only ViewController — Reactor 바인딩 불필요 (Check 4 경고만 발생) |
| `TurnipPriceResultViewController.swift` | UI-only ViewController — Reactor 바인딩 불필요 (Check 4 경고만 발생) |

## Allowlist 수정 방법

### 스크립트 내 ALLOWLIST 배열

각 스크립트 파일 상단에 Bash 배열로 allowlist가 정의되어 있다.

- `validate-architecture.sh`: `ALLOWLIST=( ... )` 및 `REVERSE_DEP_ALLOWLIST=( ... )`
- `validate-patterns.sh`: `BIND_ALLOWLIST=( ... )` 및 Check 3 내부 조건문

### 기존 위반 수정 후 allowlist에서 제거하는 절차

1. 해당 파일의 위반 사항을 수정한다 (예: `CoreData*Storage` 구체 클래스 대신 프로토콜 추상화 사용).
2. `make validate`를 실행하여 수정이 올바른지 확인한다.
3. 스크립트 파일을 열어 해당 파일 경로를 allowlist 배열에서 제거한다.
4. 다시 `make validate`를 실행하여 에러 없이 통과하는지 확인한다.
5. 변경 사항을 커밋한다.

## CI 통합

**파일**: `.github/workflows/architecture-check.yml`

| 항목 | 값 |
|------|---|
| Trigger | `develop` 브랜치 대상 PR 또는 PR 코멘트 `/arch` |
| Runner | `ubuntu-latest` |
| 실행 순서 | `validate-architecture.sh` → `validate-patterns.sh` → `validate-docs.sh` |

순수 Bash 스크립트이므로 macOS runner가 필요하지 않다. `ubuntu-latest`에서 실행되어 CI 비용과 대기 시간을 절약한다.

## 현재 한계점 및 향후 방향

현재 하네스는 **정적 구조 검증** (grep/find 기반) 에 집중되어 있다. OpenAI Harness Engineering이 말하는 "반복 가능한 현실 태스크 기반 평가/회귀 측정"까지는 아직 도달하지 못한 상태다.

### 현재 커버 범위

- 레이어 간 의존성 규칙 위반 검출 (정적)
- Reactor/Coordinator 패턴 규약 준수 여부 (정적)
- 문서 경로 참조 유효성 (정적)

### 향후 추가 고려 사항

- **태스크 기반 eval harness**: 에이전트에게 실제 작업(예: "새 화면 추가", "버그 수정")을 수행시키고, 결과의 성공률/품질을 측정하는 평가 체계
- **회귀 테스트**: 모델/프롬프트/도구 변경 시 기존 태스크 수행 품질이 저하되지 않았는지 자동 확인
- **유닛 테스트 인프라**: 현재 테스트 타겟이 없으므로, 테스트 기반 검증을 추가하면 eval harness의 기반이 될 수 있다

## 로컬 실행

### Pre-commit Hook 설정

```bash
make setup
```

`make setup` 실행 시 `git config core.hooksPath .githooks`가 자동 설정된다. 이후 모든 `git commit` 전에 `.githooks/pre-commit`이 실행되어 `make validate`를 자동 수행한다.

### 우회 방법

```bash
git commit --no-verify
```

`--no-verify` 플래그로 pre-commit hook을 우회할 수 있지만, 아키텍처 위반이 CI에서 감지되므로 **비추천**한다. 긴급 상황에서만 사용할 것.

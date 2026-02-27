# Build and Run

## Prerequisites

- macOS, Xcode 16+
- Mise (toolchain manager)
- Tuist 4.115.1 (`.mise.toml`에 고정)

## Setup

```bash
# Mise 설치
curl https://mise.run | sh

# Tuist 설치 (.mise.toml 기반)
mise install
```

## Build Commands

```bash
# SPM 의존성 설치
mise x -- tuist install

# Xcode 프로젝트 생성 (CLI 전용)
mise x -- tuist generate --no-open

# Xcode 프로젝트 생성 + 열기
mise x -- tuist generate

# CLI 빌드
mise x -- tuist build

# xcodebuild로 직접 빌드
xcodebuild \
  -workspace Animal-Crossing-Wiki.xcworkspace \
  -scheme ACNH-wiki \
  -destination generic/platform="iOS Simulator" \
  -configuration Debug \
  build
```

> 설정 변경 후 반드시 `mise x -- tuist generate` 재실행

## SwiftLint

```bash
# 검사
swiftlint --config .swiftlint.yml

# 자동 수정
swiftlint --config .swiftlint.yml --fix
```

- 빌드 시 자동 실행 (pre-build script)
- Config: `.swiftlint.yml`
- Script: `Scripts/SwiftLintRunScript.sh`
- 제외 파일: `Items.swift`, `AppDelegate.swift`, `SceneDelegate.swift`

## Validation

아키텍처 경계와 패턴 규약을 검증하는 스크립트:

```bash
# 아키텍처 경계 검증 (레이어 간 import 규칙)
bash scripts/validate-architecture.sh

# 패턴 규약 검증 (Reactor/Coordinator 패턴)
bash scripts/validate-patterns.sh

# 전체 검증 (Makefile 사용)
make validate

# CI 전체 흐름 (린트 + 검증 + 빌드)
make ci
```

자세한 내용은 [validation.md](validation.md) 참조.

### Pre-commit Hook

`make setup` 실행 시 `.githooks/pre-commit`이 자동으로 설정됨.
커밋 전 `make validate`가 자동 실행되어 위반 시 커밋 차단.

## CI/CD

**File**: `.github/workflows/develop-build.yml`

| 항목 | 값 |
|------|---|
| Trigger | PR to `develop` 또는 PR 코멘트 `/build` |
| Runner | `macos-26` |
| Xcode | 26.1.1 |
| Swift | 6.2 |

## Project Config Files

| File | 역할 |
|------|------|
| `.mise.toml` | Tuist 버전 고정 |
| `Tuist/Package.swift` | SPM 의존성 정의 |
| `Tuist/ProjectDescriptionHelpers/` | 빌드 스크립트, 의존성 헬퍼 |
| `Tuist/ProjectDescriptionHelpers/` | 빌드 스크립트, 의존성 헬퍼 |
| `Projects/App/Project.swift` | 앱 타겟/스킴/스크립트 정의 |
| `Workspace.swift` | 워크스페이스 정의 |

## Localization

리소스 위치: `Projects/App/Resources/`

```
Resources/
├── ko.lproj/Localizable.strings  # 한국어
└── en.lproj/Localizable.strings  # 영어
```

새 문자열 추가 시 **반드시 양쪽 파일 모두** 업데이트.
코드에서는 `"key".localized` 패턴 사용.

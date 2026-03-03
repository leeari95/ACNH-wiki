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

### SwiftLint 규칙 상세

`.swiftlint.yml` 설정 기반. 코드 작성 시 아래 규칙을 준수할 것.

#### 네이밍 (identifier_name)

| 항목 | 값 |
|------|---|
| 최소 길이 (warning) | **2자** |
| 최소 길이 (error) | **4자** |
| 최대 길이 | 40자 (기본값) |
| 예외 허용 | `a`, `b` |

```swift
// ✅ Good
let item = items.first
for index in 0..<count { ... }
items.map { item in item.name }

// ❌ Bad — 1글자 변수명 (a, b 제외)
let v = view           // identifier_name violation: 'v'
items.map { i in ... } // identifier_name violation: 'i'
for x in array { ... } // identifier_name violation: 'x'

// ✅ 예외: a, b는 허용
let a = pointA
let b = pointB
```

> **주의**: 클로저 파라미터에서 `$0` 사용은 린트 위반이 아니지만, 명시적 이름 사용 권장.

#### 길이 제한

| 규칙 | Warning | Error |
|------|---------|-------|
| **line_length** | 140자 | — |
| **function_body_length** | 200줄 | 300줄 |
| **type_body_length** | 500줄 | 500줄 |
| **file_length** | 1000줄 | 1200줄 |

```swift
// ✅ 한 줄이 140자를 넘기면 줄바꿈
let cell = collectionView.dequeueReusableCell(
    withReuseIdentifier: ItemCell.className,
    for: indexPath
)
```

#### 비활성화된 규칙 (disabled_rules)

아래 규칙은 **검사하지 않음** — 이 규칙을 위반해도 경고/에러 없음:

| 규칙 | 설명 |
|------|------|
| `colon` | 콜론 앞뒤 공백 |
| `control_statement` | if/for 등 괄호 사용 |
| `trailing_whitespace` | 줄 끝 공백 |
| `vertical_parameter_alignment` | 파라미터 세로 정렬 |
| `cyclomatic_complexity` | 분기 복잡도 |
| `void_function_in_ternary` | 삼항 연산자 내 void 함수 |
| `comment_spacing` | 주석 공백 |
| `function_parameter_count` | 함수 파라미터 개수 |

#### 옵트인 규칙 (opt_in_rules)

아래 규칙은 **추가로 활성화**됨:

| 규칙 | 설명 | 예시 |
|------|------|------|
| `empty_count` | `.count == 0` 대신 `.isEmpty` 사용 | `if array.isEmpty { }` ✅ |
| `conditional_returns_on_newline` | guard/if의 return은 새 줄에 | 아래 참조 |

```swift
// ✅ Good — return이 새 줄에
guard condition else {
    return
}

// ❌ Bad — return이 같은 줄에
guard condition else { return }
```

#### 린트 제외 대상

| 파일/경로 | 사유 |
|-----------|------|
| `AppDelegate.swift` | 보일러플레이트 |
| `SceneDelegate.swift` | 보일러플레이트 |
| `Items.swift` | 중앙 데이터 허브, 규칙 예외 필요 |
| `Tuist/` | 빌드 설정 파일 |
| `Workspace.swift` | Tuist 워크스페이스 정의 |
| `Projects/*/Project.swift` | Tuist 프로젝트 정의 |

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

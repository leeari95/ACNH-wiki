# CLAUDE.md

너굴포털+ (ACNH-wiki) — 모여봐요 동물의 숲 가이드 iOS 앱.
UIKit + RxSwift + ReactorKit. 단일 App 모듈, Tuist 빌드 시스템.

## Documentation Map

| 목적 | 문서 |
|------|------|
| 아키텍처 전체 구조 | [docs/architecture.md](docs/architecture.md) |
| Reactor 작성법 | [docs/patterns/reactor-pattern.md](docs/patterns/reactor-pattern.md) |
| Coordinator 작성법 | [docs/patterns/coordinator-pattern.md](docs/patterns/coordinator-pattern.md) |
| 데이터 흐름 (Items.shared) | [docs/patterns/data-flow.md](docs/patterns/data-flow.md) |
| 새 화면 추가 | [docs/guides/add-new-screen.md](docs/guides/add-new-screen.md) |
| API 엔드포인트 추가 | [docs/guides/add-api-endpoint.md](docs/guides/add-api-endpoint.md) |
| CoreData 엔티티 추가 | [docs/guides/add-coredata-entity.md](docs/guides/add-coredata-entity.md) |
| 빌드 / CI / SwiftLint | [docs/guides/build-and-run.md](docs/guides/build-and-run.md) |
| Dashboard 기능 | [docs/features/dashboard.md](docs/features/dashboard.md) |
| Catalog + Animals 기능 | [docs/features/catalog.md](docs/features/catalog.md) |
| TurnipPrices 기능 | [docs/features/turnip-prices.md](docs/features/turnip-prices.md) |
| MusicPlayer 기능 | [docs/features/music-player.md](docs/features/music-player.md) |
| iCloud Sync 기능 | [docs/features/icloud-sync.md](docs/features/icloud-sync.md) |
| 네이밍/용어 사전 | [docs/glossary.md](docs/glossary.md) |
| 함정 목록 (필독) | [docs/gotchas.md](docs/gotchas.md) |
| 검증 스크립트 가이드 | [docs/guides/validation.md](docs/guides/validation.md) |

## Build Commands

```bash
mise install                             # Tuist 4.115.1 설치
mise x -- tuist install                  # SPM 의존성 설치
mise x -- tuist generate --no-open       # Xcode 프로젝트 생성
mise x -- tuist build                    # CLI 빌드
swiftlint --config .swiftlint.yml        # 린트 검사
swiftlint --config .swiftlint.yml --fix  # 자동 수정
make validate                            # 아키텍처 + 패턴 검증
make ci                                  # 린트 + 검증 + 빌드 (CI 전체 흐름)
```

## Key Paths

| Path | 역할 |
|------|------|
| `Projects/App/Sources/` | 앱 소스 루트 |
| `Projects/App/Sources/Presentation/` | UI 레이어 (6 features) |
| `Projects/App/Sources/Utility/Items.swift` | 중앙 데이터 허브 싱글톤 |
| `Projects/App/Sources/Coordinator.swift` | Coordinator 프로토콜 |
| `Projects/App/Resources/{ko,en}.lproj/` | 로컬라이제이션 |
| `Tuist/Package.swift` | SPM 의존성 |
| `Projects/App/Project.swift` | Tuist 프로젝트 정의 |
| `.swiftlint.yml` | SwiftLint 설정 |
| `scripts/validate-architecture.sh` | 아키텍처 경계 검증 |
| `scripts/validate-patterns.sh` | 패턴 규약 검증 |
| `Makefile` | 빌드/검증/린트 타겟 |

## Critical Rules

1. 서드파티 라이브러리 추가 금지 (팀 승인 필요)
2. RxSwift 관련 패키지는 `.framework` (dynamic) 유지 → [gotchas.md](docs/gotchas.md) #1
3. 화면 전환은 반드시 Coordinator를 통해 수행
4. ReactorKit 패턴 준수: Action → mutate() → Mutation → reduce() → State
5. 설정 변경 후 `mise x -- tuist generate` 재실행

## Language

- 코드와 사고 과정은 영어
- 최종 응답은 한국어

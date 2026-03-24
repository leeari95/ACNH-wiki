# Dashboard Feature

홈 화면. 유저 프로필, 일일 태스크, 주민, 수집 진행도, NPC 방문 현황을 한 화면에 표시.

## Structure

```
Presentation/Dashboard/
├── Coordinator/
│   └── DashboardCoordinator.swift
├── ViewControllers/
│   ├── DashboardViewController.swift      # 메인 화면 (섹션 스크롤)
│   ├── PreferencesViewController.swift    # 설정 (modal)
│   ├── AboutViewController.swift          # 앱 정보 (modal)
│   ├── TaskEditViewController.swift       # 태스크 편집 (modal)
│   ├── CustomTaskViewController.swift     # 커스텀 태스크 추가/편집 (push)
│   └── IconChooserViewController.swift    # 아이콘 선택 (modal)
├── ViewModels/
│   ├── DashboardReactor.swift             # 메인 (라우팅만)
│   ├── UserInfoReactor.swift              # 유저 프로필 섹션
│   ├── TodaysTasksSectionReactor.swift    # 일일 태스크 섹션
│   ├── VillagersSectionReactor.swift      # 주민 섹션
│   ├── CollectionProgressSectionReactor.swift  # 수집 진행도 섹션
│   ├── NpcsSectionReactor.swift           # NPC 섹션 (fixedVisit / randomVisit 2개 인스턴스)
│   ├── PreferencesReactor.swift           # 설정 화면
│   ├── AppSettingReactor.swift            # 앱 설정
│   ├── AboutReactor.swift                 # 앱 정보
│   ├── TasksEditReactor.swift             # 태스크 편집
│   ├── CustomTaskReactor.swift            # 커스텀 태스크
│   └── ProgressReactor.swift              # CollectionProgress 화면
└── Views/
    ├── UserInfoView.swift
    ├── TodaysTasksView.swift
    ├── VillagersView.swift
    ├── CollectionProgressView.swift
    ├── NpcsView.swift
    ├── PreferencesView.swift
    ├── AppSettingView.swift
    ├── CustomTaskView.swift
    └── shared/                            # 앱 전체 공유 컴포넌트
        ├── LoadingView.swift
        ├── EmptyView.swift
        ├── ProgressView.swift
        ├── ProgressBar.swift
        ├── SectionView.swift
        ├── SectionHeaderView.swift
        └── IconCell.swift
```

## Multi-Reactor Pattern

DashboardViewController는 부모 Reactor + 6개 자식 Reactor를 받음:

```swift
// DashboardCoordinator.swift:40-51
viewController.bind(to: DashboardReactor(coordinator: self))
viewController.setUpViewModels(
    userInfoVM: UserInfoReactor(coordinator: self),
    tasksVM: TodaysTasksSectionReactor(coordinator: self),
    villagersVM: VillagersSectionReactor(coordinator: self),
    progressVM: CollectionProgressSectionReactor(coordinator: self),
    fixeVisitdNPCListVM: NpcsSectionReactor(state: .init(), mode: .fixedVisit, coordinator: self),
    randomVisitNPCListVM: NpcsSectionReactor(state: .init(), mode: .randomVisit, coordinator: self)
)
```

## Coordinator Routes (13개)

| Route | Presentation | 설명 |
|-------|-------------|------|
| `.setting` | modal | 설정 화면 |
| `.about` | modal | 앱 정보 |
| `.taskEdit` | modal | 태스크 편집 |
| `.customTask(task:)` | push | 커스텀 태스크 (add/edit 모드) |
| `.iconChooser` | modal | 아이콘 선택 |
| `.villagerDetail(villager:)` | modal | 주민 상세 |
| `.npcDetail(npc:)` | modal | NPC 상세 |
| `.progress` | push | 수집 진행도 |
| `.item(category:)` | push | 아이템 목록 |
| `.itemDetail(item:)` | push | 아이템 상세 |
| `.keyword(title:keyword:)` | push | 키워드 아이템 |
| `.pop` | pop | 뒤로 |
| `.dismiss` | dismiss | 닫기 |

## Special Patterns

- **CustomTaskViewControllerDelegate**: DashboardCoordinator가 IconChooser → CustomTaskVC 간 아이콘 선택 결과를 전달하는 delegate
- **showAlert()**: DashboardCoordinator의 `showAlert(title:message:) -> Observable<Bool>` 메서드로 확인 다이얼로그 표시
- **showRecoveryResultAlert()**: (TEMPORARY) iCloud 데이터 복구 결과 알림. 성공 시 앱 종료 유도
- **HapticManager**: 주민/NPC 상세 표시 시 success 햅틱 피드백

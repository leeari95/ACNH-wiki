# MusicPlayer Feature

K.K. Slider 음악 재생기. **자체 Coordinator가 없고 AppCoordinator가 직접 관리**.

## Structure

```
Presentation/MusicPlayer/
├── PlayerMode.swift                    # minimize/maximize 모드 enum
├── ViewControllers/
│   └── PlayerViewController.swift      # 플레이어 UI
├── ViewModels/
│   └── PlayerReactor.swift             # 재생 상태 관리
└── Views/
    ├── MaximizePlayerView.swift        # 확장 뷰
    ├── MinimizePlayerView.swift        # 축소 뷰
    ├── SongRow.swift                   # 노래 행
    └── SongRow.xib                     # XIB 레이아웃
```

## AppCoordinator에서의 관리

`AppCoordinator.swift`가 PlayerViewController의 생명주기를 직접 제어:

```swift
// 표시: 탭바 위 오버레이로 추가
func showMusicPlayer()

// 축소: 하단에 80pt 미니 플레이어
func minimize()

// 확장: 450pt 큰 플레이어
func maximize()

// 제거
func removePlayerViewController()
```

PlayerViewController는 탭바 **위**에 `addSubview`로 배치.
topAnchor constraint 조절 + spring animation으로 minimize/maximize 전환.

## Audio Engine: MusicPlayerManager

**File**: `Utility/MusicPlayerManager.swift` (싱글톤)

- `AVPlayer`로 오디오 재생
- `BehaviorRelay`로 상태 관리 (isPlaying, currentSong, progress 등)
- 백그라운드 재생 지원
- `MPRemoteCommandCenter` 연동 (잠금화면 컨트롤)
- 재생 모드: shuffle, fullRepeat, oneSongRepeat

## 데이터 흐름

```
Items.shared.categoryList[.songs] → MusicPlayerManager.shared.songList
    ↓
PlayerReactor.mutate(.fetch) → Mutation.setSongs
    ↓
PlayerViewController UI 업데이트
```

## 주의사항

- 별도 Coordinator를 만들지 말 것 → [gotchas.md](../gotchas.md) #10
- `PlayerReactor`의 coordinator 타입은 `AppCoordinator`

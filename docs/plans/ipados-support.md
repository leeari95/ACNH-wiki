# iPadOS Native Support Plan

> Status: Phase 1~4 Implemented, Phase 5 Pending
> Target: iPadOS 16.0+ (matching current deployment target)
> Last updated: 2026-04-12

## Executive Summary

The app currently ships as a Universal binary (`TARGETED_DEVICE_FAMILY = 1,2`) but forces compact layout on iPad via `traitOverrides.horizontalSizeClass = .compact` (AppCoordinator.swift:26). This plan converts the app to a first-class iPad citizen with adaptive layouts, sidebar navigation, keyboard/pointer support, multi-window, and Stage Manager optimization.

---

## 1. Current State Analysis

### What works
| Area | Status | Notes |
|------|--------|-------|
| Device family | Universal (1,2) | Already runs on iPad |
| Orientation | Portrait + Landscape | Info.plist supports both |
| PlayerViewController | iPad-aware | Centers minimizeView on iPad |
| TurnipPriceResultView | Partial | Uses `horizontalSizeClass` + `UIDevice.current.userInterfaceIdiom` |
| UITableView (insetGrouped) | Adaptive | Auto-margins on iPad |
| Auto Layout (safeArea) | Used consistently | Good foundation |

### Critical gaps
| Area | Issue | Impact |
|------|-------|--------|
| UIRequiresFullScreen | `true` in Info.plist | Blocks Split View / Slide Over multitasking |
| UIApplicationSupportsMultipleScenes | `false` in Info.plist | No multi-window / Stage Manager support |
| Trait override | Forces `.compact` globally (iOS 18+) | Blocks all adaptive behavior |
| CollectionView sizing | Fixed item sizes (105x140, 105x175, 50x50) | Wastes screen space |
| Layout system | `UICollectionViewFlowLayout` only | No compositional/adaptive layout |
| SectionsScrollView | Fixed `-40pt` width constraint | Content doesn't scale |
| Modal presentations | All full-screen/sheet | No popover adaptation |
| Sidebar navigation | None | Tab bar only |
| Keyboard shortcuts | None | No hardware keyboard support |
| Pointer/cursor | None | No hover/pointer interactions |
| State restoration | None | No `userActivity` handling |
| Drag & Drop | None | No `UIDragInteraction` / `UIDropInteraction` |
| XIB device targets | All target iPhone (`retina6_1`) | No iPad-optimized cell layouts |

---

## 2. Architecture Strategy

### Approach: Incremental Adaptive Enhancement

Rather than a full rewrite, each phase wraps existing UIKit components in adaptive containers. The Coordinator pattern already decouples navigation from view controllers, making it the ideal injection point for iPad-specific navigation.

### Key decisions
1. **Remove compact override** — The existing `traitOverrides.horizontalSizeClass = .compact` will be removed; all adaptive behavior flows from the system's real size classes.
2. **UISplitViewController as root** — On iPad regular width, replace UITabBarController with a `UISplitViewController` (triple-column style on iPadOS 16+). On compact width (iPhone, iPad slide-over), fall back to the existing tab bar.
3. **UICollectionViewCompositionalLayout** — Replace all `UICollectionViewFlowLayout` instances with compositional layouts using `NSCollectionLayoutEnvironment` for adaptive column counts.
4. **No new dependencies** — All changes use UIKit/SwiftUI built-in APIs only (per Critical Rule #1).

---

## 3. Implementation Phases

### Phase 1: Foundation — Adaptive Layout Infrastructure
**Goal**: Remove compact override, make existing views render correctly on iPad screens.

#### 1.1 Info.plist: Enable multitasking
- **File**: `Info.plist`
- **Changes**:
  - Remove `UIRequiresFullScreen` (or set to `false`) — enables Split View and Slide Over on iPad
  - This is the first prerequisite; without it, iPadOS multitasking is entirely blocked.
- **Risk**: The app must correctly handle being resized to 1/3, 1/2, or 2/3 screen width. All subsequent layout work addresses this.

#### 1.2 Remove trait override in AppCoordinator
- **File**: `AppCoordinator.swift`
- **Change**: Remove `rootViewController.traitOverrides.horizontalSizeClass = .compact`
- Keep `rootViewController.mode = .tabBar` for iOS 18 tab bar sidebar behavior
- **Risk**: Every screen must handle regular width. This is the "big bang" change — all subsequent tasks fix issues revealed by it.

#### 1.3 Adaptive SectionsScrollView
- **File**: `Presentation/Dashboard/Views/shared/SectionsScrollView.swift`
- **Change**: Replace fixed `widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)` with a `readableContentGuide`-based or max-width constraint.
- **Proposed logic**:
  ```swift
  // Limit content width on wide screens for readability
  let maxWidth: CGFloat = 700
  let widthConstraint = contentStackView.widthAnchor.constraint(
      lessThanOrEqualToConstant: maxWidth
  )
  widthConstraint.priority = .required
  let fillConstraint = contentStackView.widthAnchor.constraint(
      equalTo: scrollView.widthAnchor, constant: -40
  )
  fillConstraint.priority = .defaultHigh
  ```
- **Affected screens**: Dashboard, VillagerDetail, NPCDetail, ItemDetail (all use SectionsScrollView)

#### 1.4 Adaptive CollectionView layouts
Replace `UICollectionViewFlowLayout` with `UICollectionViewCompositionalLayout` in all grid views.

| ViewController | Current size | Target behavior |
|---------------|-------------|-----------------|
| ItemsViewController | 105x175 | 3-6 columns adaptive by width |
| VillagersViewController | 105x140 | 3-6 columns adaptive by width |
| NPCViewController | 105x140 | 3-6 columns adaptive by width |
| IconChooserViewController | 50x50 | 5-10 columns adaptive by width |

- **Pattern**: Create a shared `AdaptiveGridLayout` factory:
  ```swift
  enum AdaptiveGridLayout {
      static func grid(
          itemWidth: CGFloat,
          itemHeight: CGFloat,
          spacing: CGFloat = 10,
          sectionInsets: NSDirectionalEdgeInsets = .init(top: 10, leading: 20, bottom: 10, trailing: 20)
      ) -> UICollectionViewCompositionalLayout {
          UICollectionViewCompositionalLayout { _, environment in
              let availableWidth = environment.container.effectiveContentSize.width
                  - sectionInsets.leading - sectionInsets.trailing
              let columns = max(3, Int(availableWidth / (itemWidth + spacing)))
              let itemSize = NSCollectionLayoutSize(
                  widthDimension: .fractionalWidth(1.0 / CGFloat(columns)),
                  heightDimension: .estimated(itemHeight)
              )
              let item = NSCollectionLayoutItem(layoutSize: itemSize)
              let group = NSCollectionLayoutGroup.horizontal(
                  layoutSize: .init(
                      widthDimension: .fractionalWidth(1.0),
                      heightDimension: .estimated(itemHeight)
                  ),
                  repeatingSubitem: item,
                  count: columns
              )
              group.interItemSpacing = .fixed(spacing)
              let section = NSCollectionLayoutSection(group: group)
              section.interGroupSpacing = spacing
              section.contentInsets = sectionInsets
              return section
          }
      }
  }
  ```
- **Files to modify**:
  - `Presentation/Catalog/ViewControllers/ItemsViewController.swift`
  - `Presentation/Animals/ViewControllers/VillagersViewController.swift`
  - `Presentation/Animals/ViewControllers/NPCViewController.swift`
  - `Presentation/Dashboard/ViewControllers/IconChooserViewController.swift`

#### 1.5 Dashboard horizontal CollectionViews
- **Views**: `VillagersView`, `NpcsView`, `TodaysTasksView` (Dashboard sections)
- **Change**: These use fixed-height horizontal scrolling collections. On iPad regular width, increase visible item count or switch to a wrapping grid layout.
- Keep horizontal scroll on compact, switch to multi-row grid on regular width using `traitCollection.horizontalSizeClass`.

#### 1.6 PlayerViewController adaptive layout
- **File**: `Presentation/MusicPlayer/ViewControllers/PlayerViewController.swift`
- **Change**: `PlayerSheetMetrics.maximizedHeight` (currently fixed at `450`) should scale with screen height. On iPad, use a larger player area or present as a proper sheet.
- Update `AppCoordinator` player constraints to use `readableContentGuide` for centering on wide screens.

---

### Phase 2: Navigation — Sidebar & Split View
**Goal**: Provide iPad-native navigation with a sidebar on regular width.

#### 2.1 Introduce UISplitViewController
- **File**: New `AdaptiveSplitCoordinator.swift` or modify `AppCoordinator.swift`
- **Strategy**:
  ```
  iPad Regular Width:
  ┌──────────┬──────────────────────────────┐
  │ Sidebar  │  Detail (NavigationController)│
  │ (tabs as │                               │
  │  list)   │                               │
  └──────────┴──────────────────────────────┘

  iPhone / iPad Compact:
  ┌─────────────────────────────────────────┐
  │  UITabBarController (existing behavior)  │
  └─────────────────────────────────────────┘
  ```
- Use `UISplitViewController(style: .doubleColumn)` for iPadOS 16+
- Sidebar content: Same 5 tabs rendered as `UICollectionView` with list layout (`UICollectionLayoutListConfiguration`)
- Detail: The existing `UINavigationController` for each feature
- **Coordinator changes**: `AppCoordinator.start()` checks `traitCollection.horizontalSizeClass`:
  - `.regular`: Initialize `UISplitViewController` as root
  - `.compact`: Initialize `UITabBarController` as root (current behavior)
  - Handle trait changes with `willTransition(to:with:)` for dynamic switching (iPad multitasking resize)

#### 2.2 Adapt Coordinator transitions for split view
- **Files**: All `*Coordinator.swift` files
- **Change**: Modal presentations (setting, about, villagerDetail, npcDetail) should use `popover` or `formSheet` on regular width.
- **Pattern**:
  ```swift
  func presentAdaptive(_ viewController: UIViewController, from source: UIViewController) {
      let nav = UINavigationController(rootViewController: viewController)
      if source.traitCollection.horizontalSizeClass == .regular {
          nav.modalPresentationStyle = .formSheet
          nav.preferredContentSize = CGSize(width: 540, height: 620)
      }
      source.present(nav, animated: true)
  }
  ```
- **Affected**: DashboardCoordinator (6 modal routes), CatalogCoordinator, AnimalsCoordinator, TurnipPricesCoordinator

#### 2.3 Tab bar sidebar (iOS 18+)
- On iOS 18+, `UITabBarController` has native sidebar support. Currently forced to `.tabBar` mode.
- **Change**: Allow `.automatic` mode on iPad, letting the system show sidebar when appropriate.
- Keep `.tabBar` only on iPhone.

---

### Phase 3: Input — Keyboard & Pointer Support
**Goal**: First-class hardware keyboard and trackpad/mouse experience.

#### 3.1 Keyboard shortcuts
- **File**: New `KeyboardShortcutManager.swift` or integrated into Coordinators
- **Implementation**: Override `keyCommands` in root view controller or use iOS 15+ `UIMenuBuilder`.

| Shortcut | Action |
|----------|--------|
| `Cmd+1~5` | Switch tabs |
| `Cmd+F` | Focus search bar |
| `Cmd+,` | Open settings |
| `Esc` | Dismiss modal / collapse player |
| `Space` | Play/pause music |
| `Cmd+Right` | Next track |
| `Cmd+Left` | Previous track |
| `Cmd+W` | Close current window (multi-window) |

- Implement via `UIKeyCommand` on the root view controller with `discoverabilityTitle` for the shortcut overlay (hold Cmd key).

#### 3.2 Pointer interactions
- **Files**: All interactive cells and buttons
- **Strategy**: Add `UIPointerInteraction` to:
  - Collection view cells (lift effect): `CatalogCell`, `VillagersCell`, `NPCCell`
  - Tab bar items (highlight effect)
  - Navigation bar buttons (highlight effect)
  - Music player controls (highlight effect)
- **Pattern** (cell-level):
  ```swift
  // In cell's init or awakeFromNib
  let interaction = UIPointerInteraction(delegate: self)
  addInteraction(interaction)
  
  // UIPointerInteractionDelegate
  func pointerInteraction(_ interaction: UIPointerInteraction, 
                          styleFor region: UIPointerRegion) -> UIPointerStyle? {
      let preview = UITargetedPreview(view: self)
      return UIPointerStyle(effect: .lift(preview))
  }
  ```

#### 3.3 Focus system
- Ensure all interactive elements are focusable for keyboard navigation (Tab key).
- Test with `UIFocusSystem` on iPadOS.

---

### Phase 4: Multitasking & Multi-Window
**Goal**: Support Stage Manager, Slide Over, Split View, and multiple windows.

#### 4.1 Multi-window support
- **File**: `SceneDelegate.swift`, `Info.plist`
- **Changes**:
  - Set `UIApplicationSupportsMultipleScenes: YES` in Info.plist (currently `false`)
  - Implement `scene(_:willConnectTo:options:)` to support new scenes
  - Each scene gets its own `AppCoordinator` + window
- **Considerations**:
  - `Items.shared` singleton is safe for multi-window (in-process shared data)
  - `CoreDataStorage.shared` is safe (single container, multiple contexts OK)
  - `MusicPlayerManager.shared` is safe (single audio session)
  - `ToastManager.shared` currently uses a single window — needs update to per-scene toast

#### 4.2 State restoration
- **File**: `SceneDelegate.swift`
- **Implementation**:
  ```swift
  func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
      let activity = NSUserActivity(activityType: "com.leeari.NookPortalPlus.browsing")
      // Encode current tab index, navigation stack state
      activity.userInfo = ["selectedTab": currentTabIndex]
      return activity
  }
  ```
- Restore selected tab and navigation position on scene reconnect.

#### 4.3 Stage Manager window sizing
- **File**: `Info.plist` or scene configuration
- Ensure minimum window size is appropriate (e.g., 320x480)
- Test all layouts at various Stage Manager window sizes (1/4, 1/2, 3/4, full)
- The adaptive layouts from Phase 1 should handle this automatically.

#### 4.4 Slide Over & Split View
- Already supported by the adaptive layout changes in Phase 1-2.
- Test that trait collection changes are handled smoothly when user drags the split handle.
- Ensure no fixed-size constraints break at narrow widths (320pt).

---

### Phase 5: Polish & Advanced Features
**Goal**: Enhance the iPad experience with platform-specific refinements.

#### 5.1 Drag & Drop
- **Catalog/Collection screens**: Enable drag to share items between windows or export item info.
- **Music Player**: Drag songs to reorder playlist.
- **Implementation**:
  ```swift
  // Collection view drag
  collectionView.dragInteractionEnabled = true
  collectionView.dragDelegate = self
  
  // Provide item data for drag
  func collectionView(_ collectionView: UICollectionView, 
                      itemsForBeginning session: UIDragSession, 
                      at indexPath: IndexPath) -> [UIDragItem] {
      let item = items[indexPath.row]
      let itemProvider = NSItemProvider(object: item.name as NSString)
      return [UIDragItem(itemProvider: itemProvider)]
  }
  ```

#### 5.2 Context menus
- Already partially available via `UIMenu` on navigation buttons.
- Add context menus (long press / right-click) to collection view cells:
  - "Add to Collection" / "Remove from Collection"
  - "Share"
  - "View Details"

#### 5.3 Toolbar
- Replace navigation bar buttons with `UIToolbar` or `UIBarButtonItem` groupings for wider screens.
- Use `UINavigationItem.style = .editor` on iPadOS 16+ for document-style toolbar when appropriate.

#### 5.4 Pencil support
- Low priority. If relevant, add drawing/marking features for island planning.

---

## 4. File Change Matrix

| File | Phase | Change type |
|------|-------|-------------|
| `Info.plist` | 1.1, 4.1 | Remove UIRequiresFullScreen, enable multi-scene |
| `AppCoordinator.swift` | 1.2, 2.1, 2.3 | Major refactor |
| `SectionsScrollView.swift` | 1.3 | Moderate |
| `ItemsViewController.swift` | 1.4 | Layout replacement |
| `VillagersViewController.swift` | 1.4 | Layout replacement |
| `NPCViewController.swift` | 1.4 | Layout replacement |
| `IconChooserViewController.swift` | 1.4 | Layout replacement |
| `VillagersView.swift` | 1.5 | Adaptive sections |
| `NpcsView.swift` | 1.5 | Adaptive sections |
| `TodaysTasksView.swift` | 1.5 | Adaptive sections |
| `PlayerViewController.swift` | 1.6 | Adaptive metrics |
| `DashboardCoordinator.swift` | 2.2 | Modal adaptation |
| `CatalogCoordinator.swift` | 2.2 | Modal adaptation |
| `AnimalsCoordinator.swift` | 2.2 | Modal adaptation |
| `TurnipPricesCoordinator.swift` | 2.2 | Modal adaptation |
| `CollectionCoordinator.swift` | 2.2 | Modal adaptation |
| `SceneDelegate.swift` | 4.1, 4.2 | Multi-window + state restoration |
| `Coordinator.swift` | 2.1 | Protocol update (optional) |
| `CatalogCell.swift` | 3.2 | Pointer interaction |
| `VillagersCell.swift` (Nib) | 3.2 | Pointer interaction |
| `ToastManager.swift` | 4.1 | Per-scene window |
| **New**: `AdaptiveGridLayout.swift` | 1.3 | Shared layout factory |
| **New**: `KeyboardShortcutManager.swift` | 3.1 | Keyboard commands |

---

## 5. Testing Strategy

### Device matrix
| Device | Screen size | Test focus |
|--------|-----------|------------|
| iPad mini (6th gen) | 8.3" | Minimum iPad size, tight layouts |
| iPad Air (5th gen) | 10.9" | Standard iPad experience |
| iPad Pro 11" | 11" | Regular use |
| iPad Pro 12.9" | 12.9" | Maximum content area |
| iPhone SE | 4.7" | Compact regression |
| iPhone 15 Pro Max | 6.7" | Large phone regression |

### Test scenarios per phase
1. **Phase 1**: All screens render without clipping/overlap at all iPad sizes. Landscape rotation works. Collection grids show appropriate column counts.
2. **Phase 2**: Sidebar appears on regular width, collapses on compact. Modal presentations use correct style. Split View multitasking works.
3. **Phase 3**: All keyboard shortcuts work. Pointer hover shows visual feedback on interactive elements. Tab key navigates focus correctly.
4. **Phase 4**: Can open multiple windows. State is restored after scene disconnect. Stage Manager resize works smoothly.
5. **Phase 5**: Drag & Drop works between windows. Context menus appear on right-click/long-press.

### Regression checklist
- [ ] iPhone experience is identical to current behavior
- [ ] iCloud sync works across all windows
- [ ] Music player works correctly with split view
- [ ] Search functionality works in all contexts
- [ ] Collection progress tracking unaffected
- [ ] Turnip price calculator responsive in all sizes
- [ ] All localized strings display correctly (ko/en)

---

## 6. Risks & Mitigations

| Risk | Severity | Mitigation |
|------|----------|------------|
| Removing compact override breaks many screens simultaneously | High | Phase 1 tackles this first; test each screen before proceeding |
| CompositionalLayout migration changes cell sizing/appearance | Medium | Keep visual parity with current design; test with screenshots |
| UISplitViewController + existing Coordinator conflicts | Medium | Coordinator protocol already abstracts navigation; split view injects at AppCoordinator level only |
| Items.shared singleton in multi-window | Low | In-process singleton is safe; BehaviorRelay updates propagate to all subscribers |
| XIB/Nib cells need pointer interaction additions | Low | Add interaction in `awakeFromNib`; no XIB structural changes needed |
| iOS 18 tab bar sidebar vs custom sidebar conflict | Medium | Use iOS 18 native sidebar when available, custom only for iOS 16-17 |

---

## 7. Priority & Effort Estimate

| Phase | Priority | Effort | Value |
|-------|----------|--------|-------|
| Phase 1: Adaptive layouts | P0 (Critical) | Large | High — Makes the app usable on iPad |
| Phase 2: Sidebar navigation | P1 (High) | Large | High — iPad-native navigation pattern |
| Phase 3: Keyboard & pointer | P1 (High) | Medium | High — Expected by iPad users |
| Phase 4: Multi-window | P2 (Medium) | Medium | Medium — Power user feature |
| Phase 5: Polish | P3 (Low) | Small | Medium — Nice-to-have refinements |

**Recommended implementation order**: Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5

Phase 1 is the prerequisite for all other phases. Phases 2 and 3 can be developed in parallel after Phase 1 is complete.

---

## 8. iPadOS Version-Specific Features

| Feature | Min. iPadOS | Notes |
|---------|-------------|-------|
| `UISplitViewController(style:)` | 14.0 | Triple-column style available |
| `UICollectionViewCompositionalLayout` | 13.0 | Core adaptive grid layout |
| `UIPointerInteraction` | 13.4 | Trackpad/mouse cursor support |
| `UIKeyCommand` + menu builder | 13.0 | Hardware keyboard shortcuts |
| `UISceneDelegate` multi-window | 13.0 | Multiple app windows |
| Tab bar sidebar (iOS 18) | 18.0 | Native sidebar mode |
| `UINavigationItem.style = .editor` | 16.0 | Document-style toolbar |
| `NSCollectionLayoutGroup.horizontal(repeatingSubitem:count:)` | 16.0 | Simplified group creation |

All features are within the app's current deployment target (iOS 16.0+).

---

## 9. References

- [Apple HIG: Designing for iPadOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-ipados)
- [Apple HIG: Layout](https://developer.apple.com/design/human-interface-guidelines/layout)
- [UISplitViewController Documentation](https://developer.apple.com/documentation/uikit/uisplitviewcontroller)
- [UICollectionViewCompositionalLayout](https://developer.apple.com/documentation/uikit/uicollectionviewcompositionallayout)
- [Supporting Multiple Windows on iPad](https://developer.apple.com/documentation/uikit/app_and_environment/scenes/supporting_multiple_windows_on_ipad)
- [Adding Pointer Interactions](https://developer.apple.com/documentation/uikit/pointer_interactions)

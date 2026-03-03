# TurnipPrices Feature

무 시세 예측 계산기. **비표준 flat 파일 구조** 사용.

## Structure (Flat)

```
Presentation/TurnipPrices/
├── TurnipPricesCoordinator.swift        # Coordinator
├── TurnipPricesViewController.swift     # 메인 입력 화면
├── TurnipPricesReactor.swift            # Reactor (State 저장)
├── TurnipPriceResultViewController.swift # 결과 화면 (modal)
├── TurnipPriceResultView.swift          # 결과 뷰
├── TurnipPricesInputView.swift          # 가격 입력 UI
├── TurnipPricesSectionsView.swift       # 요일별 섹션
├── TurnipPricesPatternSelectionView.swift # 패턴 선택
├── FirstBuySelectionView.swift          # 첫 구매 여부
├── TurnipPriceRangeData.swift           # 가격 범위 데이터
└── TurnipPricePresentationAnimator.swift # 결과 화면 전환 애니메이션
```

> Coordinator/, ViewControllers/, ViewModels/, Views/ 하위 폴더가 **없음**. 의도된 구조.

## Coordinator Routes

| Route | Presentation | 설명 |
|-------|-------------|------|
| `.showResult(basePrice:pattern:minPrices:maxPrices:)` | modal | 계산 결과 표시 |
| `.showValidationAlert(message:)` | alert | 입력 검증 오류 |

## Reactor State

`TurnipPricesReactor.State`:
- `selectedPattern: TurnipPricePattern` - 선택된 패턴
- `isFirstBuy: Bool` - 첫 구매 여부
- `sundayPrice: String` - 일요일 구매가
- `prices: [DayOfWeek: [Period: String]]` - 요일/오전오후별 가격
- `calculatedPrices`, `calculatedBasePrice`, `calculatedPattern` - 계산 결과

## Nested Types in Reactor

```swift
enum DayOfWeek: String, CaseIterable, Codable {
    case monday, tuesday, wednesday, thursday, friday, saturday
}

enum Period: String, CaseIterable, Codable {
    case am, pm
}
```

## Calculation Logic

실제 계산은 Utility 레이어에서 수행:
- `Utility/TurnipPriceCalculator.swift` - 무 시세 계산 (Resead 알고리즘 기반)
- `Utility/TurnipPricePredictor.swift` - 가격 예측
- `Utility/SeadRandom.swift` - PRNG

## 주의사항

- flat 구조를 유지할 것 → [gotchas.md](../gotchas.md) #2
- 결과 화면은 custom `TurnipPricePresentationAnimator`로 표시

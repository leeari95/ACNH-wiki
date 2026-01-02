# 무 가격 예측 결과 차이 분석

ac-nh-turnip-prices 프로젝트와 너굴포털 무트코인의 예측 결과가 다른 이유를 분석합니다.

## 핵심 차이점 요약

### 1. **하락 구간 계산 방식이 완전히 다름** ⚠️ 가장 큰 문제

#### JavaScript (올바른 구현)
```javascript
// PATTERN 0: Decreasing Phase
rate = randfloat(0.8, 0.6);  // 초기 rate: 0.6~0.8
for (int i = 0; i < decPhaseLen1; i++) {
  sellPrices[work++] = intceil(rate * basePrice);
  rate -= 0.04;              // 고정 감소
  rate -= randfloat(0, 0.06); // 랜덤 감소 (0~0.06)
}
```

**동작:**
- 초기 rate: 0.6~0.8
- 각 단계마다 **누적 감소**: 0.04 + (0~0.06) = **0.04~0.1 감소**
- 1단계: 0.6~0.8
- 2단계: 0.5~0.76 (최소: 0.6-0.1, 최대: 0.8-0.04)
- 3단계: 0.4~0.72 (최소: 0.5-0.1, 최대: 0.76-0.04)

#### Swift (현재 잘못된 구현)
```swift
for i in 0..<decPhase1Len {
    let rate = 0.6 + (0.8 - 0.6) * Double(decPhase1Len - i - 1) / Double(decPhase1Len)
    if !setPrice(&minPrices, &maxPrices, work, rateMin: rate - 0.1, rateMax: rate) {
```

**동작:**
- **선형 보간 방식**: 0.8에서 0.6으로 균등하게 분할
- decPhase1Len=3일 때:
  - i=0: rate = 0.6 + 0.2 * 2/3 = 0.73
  - i=1: rate = 0.6 + 0.2 * 1/3 = 0.67
  - i=2: rate = 0.6 + 0.2 * 0/3 = 0.60
- rateMin = rate - 0.1, rateMax = rate
- 결과가 JavaScript와 완전히 다름!

**올바른 Swift 구현:**
```swift
for i in 0..<decPhase1Len {
    let minRate = max(0.0, 0.6 - Double(i) * 0.1)  // 최소: 매번 0.1 감소
    let maxRate = max(0.0, 0.8 - Double(i) * 0.04) // 최대: 매번 0.04 감소
    setPrice(&minPrices, &maxPrices, work, rateMin: minRate, rateMax: maxRate)
}
```

---

### 2. **확률 계산 여부**

#### JavaScript
- PDF (Probability Density Function) 클래스 사용
- 각 조합마다 **조건부 확률** 계산
- 입력값이 있으면 rate 범위를 역산하고 교집합 계산
- 확률이 0인 조합은 제외

```javascript
probability *= this.generate_individual_random_price(
    given_prices, predicted_prices, 2, high_phase_1_len, 0.9, 1.4);
if (probability == 0) {
  return;
}
```

#### Swift
- **확률 계산 없음**
- 모든 조합을 동등하게 취급
- 단순히 모든 결과의 min/max 통합

---

### 3. **입력값 처리 방식**

#### JavaScript
```javascript
if (!isNaN(given_prices[i])) {
  // 입력값으로부터 가능한 rate 범위 역산
  const real_rate_range =
      this.rate_range_from_given_and_base(clamp(given_prices[i], min_pred, max_pred), buy_price);

  // PDF를 해당 범위로 제한
  prob *= rate_pdf.range_limit(real_rate_range);

  if (prob == 0) {
    return 0;  // 이 조합은 불가능
  }
}
```

**역산 공식:**
```javascript
minimum_rate_from_given_and_base(given_price, buy_price) {
  return RATE_MULTIPLIER * (given_price - 0.99999) / buy_price;
}

maximum_rate_from_given_and_base(given_price, buy_price) {
  return RATE_MULTIPLIER * (given_price + 0.00001) / buy_price;
}
```

#### Swift (수정 후)
```swift
if let givenPrice = givenPrices[index] {
    minPrices[index] = givenPrice
    maxPrices[index] = givenPrice
} else {
    minPrices[index] = intCeil(rateMin * Double(basePrice))
    maxPrices[index] = intCeil(rateMax * Double(basePrice))
}
```

- 입력값이 있으면 무조건 사용
- **역산이나 확률 계산 없음**

---

### 4. **RATE_MULTIPLIER 사용**

#### JavaScript
```javascript
const RATE_MULTIPLIER = 10000;

// rate를 정수로 변환하여 정밀도 유지
rate_min *= RATE_MULTIPLIER;
rate_max *= RATE_MULTIPLIER;
```

#### Swift
- rate를 Double로 직접 사용
- 부동소수점 오차 가능성

---

## 결과 차이의 원인

1. **하락 구간 계산 오류** (가장 큰 원인)
   - Swift는 선형 보간을 사용하지만, 실제 게임은 누적 감소 방식
   - 하락 폭이 완전히 다름

2. **확률 계산 부재**
   - JavaScript는 PDF 기반 정확한 범위 계산
   - Swift는 모든 조합의 min/max만 통합

3. **입력값 역산 부재**
   - JavaScript는 입력값에서 가능한 rate 범위를 역산
   - Swift는 입력값을 그대로 사용하고 나머지만 예측

## 예상되는 차이

### 구매가 100, 월요일 AM 90 입력 시

#### JavaScript 결과 예시:
- 월요일 PM: 85~95 (확률 계산 후 좁혀진 범위)
- 화요일 AM: 80~100
- 화요일 PM: 75~110

#### Swift 현재 결과 예시:
- 월요일 PM: 60~140 (모든 패턴의 전체 범위)
- 화요일 AM: 50~140
- 화요일 PM: 40~200

**Swift가 더 넓은 범위를 보여줌** - 확률 기반 필터링이 없기 때문

---

## 해결 방안

### 단기 해결 (간단)
1. **하락 구간 계산 수정** - 누적 감소 방식으로 변경
2. 다른 패턴들도 JavaScript 구현과 정확히 일치하도록 수정

### 장기 해결 (복잡하지만 정확)
1. PDF 클래스 구현
2. 확률 기반 필터링 구현
3. 입력값 역산 로직 구현
4. RATE_MULTIPLIER 사용

---

## 결론

현재 Swift 구현은:
- ✅ 패턴 조합 생성 로직은 비슷함
- ❌ **하락 구간 계산이 완전히 잘못됨** (선형 보간 vs 누적 감소)
- ❌ 확률 계산이 없어 범위가 너무 넓음
- ❌ 입력값 역산이 없어 예측 정확도가 낮음

**우선순위:**
1. 하락 구간 계산 수정 (필수)
2. 다른 패턴들의 rate 범위 검증
3. (선택) PDF 기반 확률 계산 구현

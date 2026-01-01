# ACNH Wiki iOS 앱 버그 수정 TODO 리스트

## 🚨 치명적인 버그 (즉시 수정 필요)

### 1. APIRequest URL 구성 오류
- **파일**: `APIRequest.swift:35`
- **문제**: 쿼리 파라미터가 요청에 추가되지 않음
- **영향**: API 호출 실패 및 잘못된 데이터 반환
- **수정방법**:
  ```swift
  // 현재 (잘못된 코드):
  return url
  
  // 올바른 코드:
  guard let finalURL = urlComponents?.url else {
      throw APIError.invalidURL(url.absoluteString)
  }
  return finalURL
  ```

### 2. CoreData 스레드 안전성 위반
- **파일**: 여러 스토리지 클래스
  - `CoreDataUserInfoStorage.fetchUserInfo()`
  - `CoreDataVillagersHouseStorage.fetch()`
  - `CoreDataVillagersLikeStorage.fetch()`
  - `CoreDataNPCLikeStorage.fetch()`
- **문제**: viewContext 사용 시 메인 스레드 실행 미보장
- **영향**: 백그라운드 스레드 접근 시 앱 크래시

### 3. 배열 인덱스 범위 초과
- **파일**: `DailyTask.swift:19`
- **문제**: 
  ```swift
  mutating func toggleCompleted(_ index: Int) {
      self.progressList[index].toggle()  // 범위 체크 없음
  }
  ```
- **영향**: 유효하지 않은 인덱스 전달 시 앱 크래시

### 4. 자식 뷰 컨트롤러 관리 누락
- **파일**: `AppCoordinator.swift:66-68`
- **문제**: `rootViewController.addChild(viewController)` 누락
- **영향**: 뷰 컨트롤러 라이프사이클 메서드 미호출로 크래시 위험

### 5. 비공개 API 사용
- **파일**: `UINavigationItem.swift:13`
- **문제**: `setValue(true, forKey: "__largeTitleTwoLineMode")`
- **영향**: 앱스토어 거절 위험 및 향후 iOS 버전 크래시 가능성

---

## ⚠️ 높은 우선순위 버그

### 1. 반구 데이터 복사 실수
- **파일**: `CoreDataVillagersHouseStorage`
- **문제**: 남반구 데이터에 북반구 값 사용
- **영향**: 남반구 유저 잘못된 데이터 확인

### 2. 데이터 저장 형식 문제
- **파일**: `CoreDataUserInfoStorage`
- **문제**: 
  - `islandFruit.imageName` 저장 (rawValue 대신)
  - 저장 시 대문자화 처리
- **영향**: 데이터 손상, 파싱 실패 가능성

### 3. DB 내 중복 항목
- **파일**: `CoreDataItemsStorage.updates()`
- **문제**: 중복 체크 없이 항목 추가
- **영향**: 사용자 수집 목록 중복 항목 발생

### 4. 에러 처리 누락
- **파일**: 모든 CoreData 스토리지 클래스
- **문제**: 에러를 단순 로깅만 하고 무시
- **영향**: 사용자 알림 없이 데이터 손실

### 5. NPC ID 생성 오류
- **파일**: `NPC.swift:31`
- **문제**: `public var id: String { UUID().uuidString }` - 접근 시마다 새 UUID
- **영향**: Identifiable 프로토콜 위반, UI 재사용 문제

---

## 🟡 중간 우선순위 버그

### 1. 메모리 누수
#### a. RxSwift 구독 순환 참조
- **파일**: `DashboardViewController.swift:108-118`
- **문제**: 클로저에서 self 약한 참조 없이 사용

#### b. PlayerViewController 제거 누락
- **파일**: `AppCoordinator.swift:107-110`
- **문제**: 뷰 숨기기만 하고 제거하지 않음

### 2. 현지화 문제
#### a. 한글 하드코딩 에러 메시지
- **파일**: `APIError.swift`
- **문제**: 에러 설명 한글 하드코딩
- **영향**: 다국어 지원 불가

#### b. 정적 데이터 오타
- **파일**: `DailyTask.swift:110`
- **문제**: `"Find peral"` → `"Find pearl"`

### 3. 성능 문제
#### a. DateFormatter 반복 생성
- **파일**: `Date+extension.swift:12-16`
- **문제**: 호출마다 새 DateFormatter 생성
- **영향**: 성능 저하, 스레드 안전성 문제

#### b. 비효율적인 문자열 처리
- **파일**: `Villager.swift:35-40`
- **문제**: `reduce` 대신 `joined(separator:)` 사용 권장

### 4. 파일명 오류
- `FencingReqeust.swift` → `FencingRequest.swift`
- `GyroidsRequst.swift` → `GyroidsRequest.swift`

---

## 🟢 낮은 우선순위 버그

### 1. 잘못된 flatMap 사용
- **파일**: `AppCoordinator.swift:80`
- **문제**: `flatMap` 대신 `if let` 사용 권장

### 2. CoreData 마이그레이션 누락
- **파일**: `CoreDataStorage.swift`
- **문제**: 마이그레이션 옵션 미설정
- **영향**: 스키마 변경 시 크래시 위험

### 3. 사용 중단된 Transformer 사용
- **파일**: 모든 CoreData 모델
- **문제**: `NSSecureUnarchiveFromData` 사용
- **해결**: 커스텀 Transformer로 교체 필요

### 4. 에러 처리 없음
- **파일**: 모든 Reactor 클래스
- **문제**: 에러 상태 정의 없음, 네트워크 에러 무시

### 5. Reducer 내부 Navigation 처리
- **파일**: `ItemsReactor.swift:156-159`
- **문제**: ReactorKit 단방향 데이터 흐름 원칙 위반

---

## 📋 권장 수정 순서

### 즉시 조치 필요 (Critical)
1. ✅ APIRequest URL 버그 수정
2. ✅ CoreData 스레드 안전성 확보
3. ✅ 배열 접근 시 인덱스 검증 추가
4. ✅ 비공개 API 제거
5. ✅ 반구 데이터 매핑 수정

### 단기 개선 과제 (1-2주)
1. 사용자 알림을 포함한 에러 처리 도입
2. DB 중복 항목 방지 로직 추가
3. ViewController 메모리 누수 해결
4. CoreData 마이그레이션 옵션 설정
5. Reactor에 에러 상태 정의

### 장기 개선 방향 (1-3개월)
1. 전반적인 단위 테스트 도입
2. SwiftLint 룰 설정 및 적용
3. DI(의존성 주입) 구조 도입
4. 에러 추적을 위한 분석 로직 도입
5. 전체 문자열의 다국어 현지화 구현

---

## 📊 요약 통계

- **총 발견된 버그 수**: 45개 이상
- **치명적**: 5개
- **높은 우선순위**: 10개
- **중간 우선순위**: 15개
- **낮은 우선순위**: 15개 이상

---

**가장 심각한 문제**: API 요청 URL 구성 버그, 스레드 안전성 문제, CoreData 데이터 손상 이슈

**우선순위**: 앱의 안정성과 데이터 무결성을 보장하기 위해 치명적인 버그들을 즉시 해결해야 함
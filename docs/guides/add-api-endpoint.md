# Add an API Endpoint

새 API 데이터 소스를 추가하는 단계별 가이드.

## Steps

### 1. Request 구조체 생성

`Networking/Request/` 하위에 생성:

```swift
import Foundation
import Alamofire

struct NewDataRequest: APIRequest {
    typealias Response = [NewDataResponseDTO]

    var method: HTTPMethod = .get
    var baseURL: URL? = URL(string: EnvironmentsVariable.repoURL)
    var path: String = "NewData.json"
    var parameters: [String: String] = [:]
    var headers: [String: String]?
}
```

- `Response` 타입은 Decodable 타입
- `baseURL`은 `EnvironmentsVariable`에서 선택
- `path`는 base URL 이후 경로

### 2. Response DTO 생성

`Networking/Response/` 하위에 생성:

```swift
import Foundation

struct NewDataResponseDTO: Decodable {
    let name: String
    let value: Int
    // JSON 구조에 맞게 정의
}
```

**Domain Model로 변환이 필요한 경우** `DomainConvertible` 채택:

```swift
extension NewDataResponseDTO: DomainConvertible {
    func toDomain() -> Item {
        return Item(
            name: name,
            category: .someCategory,
            // ...
        )
    }
}
```

### 3. Items.swift에 연결 (앱 전역 데이터인 경우)

`Utility/Items.swift`에서:

1. BehaviorRelay 추가:
```swift
private let newData = BehaviorRelay<[NewData]>(value: [])
```

2. 적절한 fetch 그룹에 호출 추가:
```swift
fetchItem(NewDataRequest(), itemKey: .newCategory, group: group) {
    itemList.merge($0) { _, new in new }
}
```

3. Observable 스트림 노출:
```swift
var newDataList: Observable<[NewData]> {
    return newData.asObservable()
}
```

## API Base URLs

| Variable | URL | 용도 |
|----------|-----|------|
| `EnvironmentsVariable.repoURL` | `https://raw.githubusercontent.com/leeari95/animal-crossing/release/3.0.0/json/data/` | 아이템, 주민, NPC JSON |
| `EnvironmentsVariable.turnupURL` | `https://api.ac-turnip.com/data/` | 무 시세 |
| `EnvironmentsVariable.acnhAPI` | `https://acnhapi.com/v1/` | 노래 |

## Reference Files

| 역할 | File |
|------|------|
| APIRequest 프로토콜 | `Networking/Protocol/APIRequest.swift` |
| APIProvider 프로토콜 | `Networking/Protocol/APIProvider.swift` |
| 구현체 | `Networking/DefaultAPIProvider.swift` |
| DomainConvertible | `Networking/Response/DomainConvertible.swift` |
| 에러 타입 | `Networking/Utilities/APIError.swift` |
| 기존 Request 예시 | `Networking/Request/Museum/BugRequest.swift` |
| 기존 DTO 예시 | `Networking/Response/Museum/BugResponseDTO.swift` |

## Network Retry

`Items.swift`에서 모든 API 호출에 자동 적용:
- 최대 3회 재시도
- Exponential backoff: 2초, 4초, 6초
- `os_log`로 실패/재시도 로깅

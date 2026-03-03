# Add a CoreData Entity

CoreData 저장소를 추가하는 단계별 가이드.

## Steps

### 1. CoreData Model 수정

Xcode에서 `Sources/CoreDataStorage/CoreDataStorage.xcdatamodeld` 열기:
- 새 Entity 추가 또는 기존 Entity에 attribute 추가
- `UserCollectionEntity`에 relationship 추가 (필요 시)

> Lightweight migration이 자동 지원됨: 속성 추가, 옵셔널 변경은 안전. 관계 변경/타입 변경은 주의 필요.

### 2. Storage 프로토콜 정의

`CoreDataStorage/XxxStorage/XxxStorage.swift`:

```swift
import Foundation
import RxSwift

protocol XxxStorage {
    func fetch() -> Single<[XxxModel]>
    func update(_ item: XxxModel)
    func reset()
}
```

### 3. CoreData 구현체

`CoreDataStorage/XxxStorage/CoreDataXxxStorage.swift`:

```swift
import Foundation
import RxSwift

final class CoreDataXxxStorage: XxxStorage {
    private let coreDataStorage: CoreDataStorage

    init(coreDataStorage: CoreDataStorage = CoreDataStorage.shared) {
        self.coreDataStorage = coreDataStorage
    }

    func fetch() -> Single<[XxxModel]> {
        return Single.create { single in
            self.coreDataStorage.performBackgroundTask { context in
                do {
                    let object = try self.coreDataStorage.getUserCollection(context)
                    // Entity에서 데이터 가져오기
                    let entities = object.xxx?.allObjects as? [XxxEntity] ?? []
                    let models = try entities.map { try $0.toDomain() }
                    single(.success(models))
                } catch {
                    single(.failure(CoreDataStorageError.readError(error)))
                }
            }
            return Disposables.create()
        }
    }

    func update(_ item: XxxModel) {
        coreDataStorage.performBackgroundTask { context in
            do {
                let object = try self.coreDataStorage.getUserCollection(context)
                // 토글 패턴: 있으면 제거, 없으면 추가
                let items = object.xxx?.allObjects as? [XxxEntity] ?? []
                if let index = items.firstIndex(where: { $0.id == item.id }) {
                    object.removeFromXxx(items[index])
                } else {
                    let newItem = XxxEntity(item, context: context)
                    object.addToXxx(newItem)
                }
                context.saveContext()
            } catch {
                debugPrint(error)
            }
        }
    }
}
```

### 4. Entity Mapping

`CoreDataStorage/XxxStorage/EntityMapping/XxxEntity+Mapping.swift`:

```swift
import Foundation
import CoreData

extension XxxEntity {
    // Domain → Entity
    convenience init(_ model: XxxModel, context: NSManagedObjectContext) {
        self.init(context: context)
        self.name = model.name
        self.value = Int64(model.value)
        // ...
    }

    // Entity → Domain
    func toDomain() throws -> XxxModel {
        guard let name = self.name else {
            throw CoreDataStorageError.notFound
        }
        return XxxModel(
            name: name,
            value: Int(self.value)
            // ...
        )
    }
}
```

### 5. Items.swift에 연결 (필요 시)

`setUpUserCollection()`에서 로드 + update 메서드 추가.

## Key Patterns

| Pattern | 설명 |
|---------|------|
| `performBackgroundTask` | 모든 쓰기 작업은 백그라운드 context 사용 |
| `getUserCollection` | `UserCollectionEntity`가 모든 컬렉션의 루트 |
| `context.saveContext()` | `NSManagedObjectContext` extension. hasChanges 체크 후 저장 |
| Toggle | update()는 존재하면 제거, 없으면 추가 (토글 패턴) |
| `Single<T>` | fetch는 RxSwift Single로 반환 |

## Reference Files

| 역할 | File |
|------|------|
| CoreData 싱글톤 | `CoreDataStorage/CoreDataStorage.swift` |
| Storage 프로토콜 예시 | `CoreDataStorage/ItemsStorage/ItemsStorage.swift` |
| 구현체 예시 | `CoreDataStorage/ItemsStorage/CoreDataItemsStorage.swift` |
| Entity 매핑 예시 | `CoreDataStorage/ItemsStorage/EntityMapping/ItemEntity+Mapping.swift` |
| Data Model | `CoreDataStorage/CoreDataStorage.xcdatamodeld` |

## 주의사항

- `NSPersistentCloudKitContainer` 사용 중 → [gotchas.md](../gotchas.md) #8
- Merge policy: `NSMergeByPropertyObjectTrumpMergePolicy`
- `viewContext.automaticallyMergesChangesFromParent = true`

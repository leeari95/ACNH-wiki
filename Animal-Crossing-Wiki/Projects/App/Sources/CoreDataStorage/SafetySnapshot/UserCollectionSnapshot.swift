//
//  UserCollectionSnapshot.swift
//  Animal-Crossing-Wiki
//
//  Stage 1.5 safety net for iOS-induced local data purges
//  (NSCloudKitMirroringDelegate의 Change Token Expired 시 로컬 wipe 대응).
//
//  - Core Data의 UserCollectionEntity + 자식 엔티티를 attribute dict로 직렬화
//  - Foundation 기본 타입만으로 구성된 NSDictionary tree → binary plist로 저장
//  - 도메인 모델 Codable 의존성 없음 (NSArray/NSDictionary transformable도 plist가 그대로 처리)
//

import Foundation
import CoreData
import os

enum SafetySnapshotError: Error {
    case serializationFailed(Error)
    case deserializationFailed(Error)
    case incompatibleVersion(found: Int, expected: Int)
    case noUserCollection
}

/// 스냅샷 스키마 버전. 하위 호환 불가한 변경 시 bump.
/// v1 — 3.2.4 최초 도입
private let kCurrentSafetySnapshotVersion: Int = 1

struct UserCollectionSnapshot {

    let version: Int
    let createdAt: Date
    let userInfo: [String: Any]
    let items: [[String: Any]]
    let dailyTasks: [[String: Any]]
    let villagersLike: [[String: Any]]
    let villagersHouse: [[String: Any]]
    let npcLike: [[String: Any]]
    let variants: [[String: Any]]

    var totalChildCount: Int {
        items.count + dailyTasks.count + villagersLike.count
            + villagersHouse.count + npcLike.count + variants.count
    }

    // MARK: - Serialization

    func toData() throws -> Data {
        let root: [String: Any] = [
            "version": version,
            "createdAt": createdAt,
            "userInfo": userInfo,
            "items": items,
            "dailyTasks": dailyTasks,
            "villagersLike": villagersLike,
            "villagersHouse": villagersHouse,
            "npcLike": npcLike,
            "variants": variants
        ]
        do {
            return try PropertyListSerialization.data(
                fromPropertyList: root,
                format: .binary,
                options: 0
            )
        } catch {
            throw SafetySnapshotError.serializationFailed(error)
        }
    }

    static func from(data: Data) throws -> UserCollectionSnapshot {
        let plist: Any
        do {
            plist = try PropertyListSerialization.propertyList(
                from: data, options: [], format: nil
            )
        } catch {
            throw SafetySnapshotError.deserializationFailed(error)
        }
        guard let dict = plist as? [String: Any],
              let version = dict["version"] as? Int,
              let createdAt = dict["createdAt"] as? Date,
              let userInfo = dict["userInfo"] as? [String: Any] else {
            throw SafetySnapshotError.deserializationFailed(
                NSError(domain: "SafetySnapshot", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Malformed snapshot root"])
            )
        }
        guard version == kCurrentSafetySnapshotVersion else {
            throw SafetySnapshotError.incompatibleVersion(
                found: version, expected: kCurrentSafetySnapshotVersion
            )
        }
        return UserCollectionSnapshot(
            version: version,
            createdAt: createdAt,
            userInfo: userInfo,
            items: (dict["items"] as? [[String: Any]]) ?? [],
            dailyTasks: (dict["dailyTasks"] as? [[String: Any]]) ?? [],
            villagersLike: (dict["villagersLike"] as? [[String: Any]]) ?? [],
            villagersHouse: (dict["villagersHouse"] as? [[String: Any]]) ?? [],
            npcLike: (dict["npcLike"] as? [[String: Any]]) ?? [],
            variants: (dict["variants"] as? [[String: Any]]) ?? []
        )
    }

    // MARK: - Dump from Core Data

    /// LocalStore(또는 main store)의 context에서 UC 그래프 전체를 덤프.
    /// UC가 여러 개면 관계가 가장 많은 하나를 선택 (기존 getUserCollection 정책과 동일).
    static func dump(from context: NSManagedObjectContext) throws -> UserCollectionSnapshot {
        var result: UserCollectionSnapshot?
        var caughtError: Error?

        context.performAndWait {
            do {
                let request = UserCollectionEntity.fetchRequest()
                let ucs = try context.fetch(request)
                guard let uc = ucs.sorted(by: { relationshipCount(of: $0) > relationshipCount(of: $1) }).first else {
                    caughtError = SafetySnapshotError.noUserCollection
                    return
                }

                let userInfoDict = attributeDict(of: uc)
                let items = children(of: uc, key: "critters")
                let tasks = children(of: uc, key: "dailyTasks")
                let vLikes = children(of: uc, key: "villagersLike")
                let vHouses = children(of: uc, key: "villagersHouse")
                let npcs = children(of: uc, key: "npcLike")
                let variants = children(of: uc, key: "variants")

                result = UserCollectionSnapshot(
                    version: kCurrentSafetySnapshotVersion,
                    createdAt: Date(),
                    userInfo: userInfoDict,
                    items: items,
                    dailyTasks: tasks,
                    villagersLike: vLikes,
                    villagersHouse: vHouses,
                    npcLike: npcs,
                    variants: variants
                )
            } catch {
                caughtError = error
            }
        }

        if let error = caughtError {
            throw error
        }
        guard let snapshot = result else {
            throw SafetySnapshotError.noUserCollection
        }
        return snapshot
    }

    // MARK: - Apply to Core Data

    /// 대상 context에 UC를 재구성. 호출자는 사전에 기존 UC + 자식을 삭제했어야 한다.
    /// 단일 background context 안에서 wipe → apply → save를 원자적으로 묶는 것이 권장.
    func apply(to context: NSManagedObjectContext) throws {
        var caughtError: Error?
        context.performAndWait {
            do {
                // UC 생성
                guard let ucEntity = NSEntityDescription.entity(
                    forEntityName: "UserCollectionEntity", in: context
                ) else {
                    throw SafetySnapshotError.deserializationFailed(
                        NSError(domain: "SafetySnapshot", code: -2,
                                userInfo: [NSLocalizedDescriptionKey: "UserCollectionEntity not in model"])
                    )
                }
                let uc = NSManagedObject(entity: ucEntity, insertInto: context)
                applyAttributes(userInfo, to: uc)

                try insertChildren(items, entityName: "ItemEntity",
                                   parent: uc, relationshipKey: "userColletion", in: context)
                try insertChildren(dailyTasks, entityName: "DailyTaskEntity",
                                   parent: uc, relationshipKey: "userCollection", in: context)
                try insertChildren(villagersLike, entityName: "VillagersLikeEntity",
                                   parent: uc, relationshipKey: "userCollection", in: context)
                try insertChildren(villagersHouse, entityName: "VillagersHouseEntity",
                                   parent: uc, relationshipKey: "userCollection", in: context)
                try insertChildren(npcLike, entityName: "NPCLikeEntity",
                                   parent: uc, relationshipKey: "userCollection", in: context)
                try insertChildren(variants, entityName: "VariantCollectionEntity",
                                   parent: uc, relationshipKey: "userCollection", in: context)
            } catch {
                caughtError = error
            }
        }
        if let error = caughtError {
            throw error
        }
    }

    private func insertChildren(
        _ dicts: [[String: Any]],
        entityName: String,
        parent: NSManagedObject,
        relationshipKey: String,
        in context: NSManagedObjectContext
    ) throws {
        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else {
            throw SafetySnapshotError.deserializationFailed(
                NSError(domain: "SafetySnapshot", code: -3,
                        userInfo: [NSLocalizedDescriptionKey: "\(entityName) not in model"])
            )
        }
        for dict in dicts {
            let obj = NSManagedObject(entity: entity, insertInto: context)
            applyAttributes(dict, to: obj)
            obj.setValue(parent, forKey: relationshipKey)
        }
    }

    // MARK: - Attribute Helpers

    private static func attributeDict(of object: NSManagedObject) -> [String: Any] {
        var dict: [String: Any] = [:]
        for (name, _) in object.entity.attributesByName {
            if let value = object.value(forKey: name) {
                // NSDate, NSString, NSNumber, NSData, NSArray, NSDictionary 모두 plist 호환
                dict[name] = value
            }
        }
        return dict
    }

    private static func children(of uc: NSManagedObject, key: String) -> [[String: Any]] {
        guard let set = uc.value(forKey: key) as? Set<NSManagedObject> else { return [] }
        return set.map { attributeDict(of: $0) }
    }

    private static func relationshipCount(of uc: NSManagedObject) -> Int {
        let keys = ["critters", "dailyTasks", "villagersLike", "villagersHouse", "npcLike", "variants"]
        return keys.reduce(0) { acc, key in
            let count = (uc.value(forKey: key) as? Set<NSManagedObject>)?.count ?? 0
            return acc + count
        }
    }

    private func applyAttributes(_ dict: [String: Any], to object: NSManagedObject) {
        for (key, _) in object.entity.attributesByName {
            if let value = dict[key] {
                object.setValue(value, forKey: key)
            }
        }
    }
}

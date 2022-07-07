//
//  ItemEntity+Mapping.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation
import CoreData

extension ItemEntity {
    
    convenience init(_ item: Item, context: NSManagedObjectContext) {
        self.init(context: context)
        self.artCategory = item.artCategory.rawValue
        self.buy = Int64(item.buy)
        self.catchDifficulty = item.catchDifficulty.rawValue
        self.category = item.category.rawValue
        self.colors = item.colors.map { $0.rawValue }
        self.concepts = item.keyword[.concept] // 머여?
        self.critterpediaImage = item.critterpediaImage
        self.furnitureImage = item.furnitureImage
        self.genuine = item.genuine
        self.hemispheres = item.hemispheres.toDictionary()
        self.highResTexture = item.highResTexture
        self.iconImage = item.iconImage
        self.image = item.image
        self.keyword = item.toKeyword()
        self.movementSpeed = item.movementSpeed.rawValue
        self.museum = item.museum.rawValue
        self.name = item.name
        self.sell = Int64(item.sell)
        self.shadow = item.shadow.rawValue
        self.size = item.size.rawValue
        self.spawnRates = item.spawnRates
        self.styles = item.keyword[.style]
        self.translations = item.translations.toDictionary()
        self.unlocked = item.unlocked
        self.vision = item.vision.rawValue
        self.weather = item.weather.rawValue
        self.whereHow = item.whereHow
        self.source = item.source
    }
    
    func toKeyword() -> [Keyword: [String]] {
        var keywordList = [Keyword: [String]]()
        self.keyword?.forEach({ (key: String, value: [String]) in
            if let keyword = Keyword(rawValue: key) {
                keywordList[keyword] = value
            }
        })
        return keywordList
    }
    
    func toDomain() throws -> Item {
        guard let category = Category(rawValue: self.category ?? "") else {
            throw CoreDataStorageError.categoryNotFound
        }
        switch category {
        case .bugs:
            return Bug(
                name: self.name ?? "",
                iconImage: self.iconImage ?? "",
                critterpediaImage: self.critterpediaImage ?? "",
                furnitureImage: self.furnitureImage ?? "",
                sell: Int(self.sell),
                whereHow: self.whereHow ?? "",
                weather: Weather(rawValue: self.weather ?? "") ?? .anyExceptRain,
                spawnRates: self.spawnRates ?? "",
                size: Size(rawValue: self.size ?? "") ?? .the1X1,
                translations: Translations(self.translations ?? [:]),
                hemispheres: Hemispheres(self.hemispheres ?? [:]),
                colors: self.colors?.compactMap { Color(rawValue: $0) } ?? [],
                keyword: toKeyword()
            )
        case .fishes:
            return Fish(
                name: self.name ?? "",
                iconImage: self.iconImage ?? "",
                critterpediaImage: self.critterpediaImage ?? "",
                furnitureImage: self.furnitureImage ?? "",
                sell: Int(self.sell),
                whereHow: self.whereHow ?? "",
                shadow: Shadow(rawValue: self.shadow ?? "") ?? .medium,
                catchDifficulty: CatchDifficulty(rawValue: self.catchDifficulty ?? "") ?? .medium,
                vision: Vision(rawValue: self.vision ?? "") ?? .medium,
                translations: Translations(self.translations ?? [:]),
                hemispheres: Hemispheres(self.hemispheres ?? [:]),
                colors: self.colors?.compactMap { Color(rawValue: $0) } ?? [],
                keyword: toKeyword()
            )
        case .seaCreatures:
            return SeaCreature(
                name: self.name ?? "",
                iconImage: self.iconImage ?? "",
                critterpediaImage: self.critterpediaImage ?? "",
                furnitureImage: self.furnitureImage ?? "",
                sell: Int(self.sell),
                shadow: Shadow(rawValue: self.shadow ?? "") ?? .medium,
                movementSpeed: MovementSpeed(rawValue: self.movementSpeed ?? "") ?? .medium,
                spawnRates: self.spawnRates ?? "",
                size: Size(rawValue: self.size ?? "") ?? .the1X1,
                translations: Translations(self.translations ?? [:]),
                hemispheres: Hemispheres(self.hemispheres ?? [:]),
                colors: self.colors?.compactMap { Color(rawValue: $0) } ?? [],
                keyword: toKeyword()
            )
        case .fossils:
            return Fossils(
                name: self.name ?? "",
                image: self.image ?? "",
                buy: Int(self.buy),
                sell: Int(self.sell),
                size: Size(rawValue: self.size ?? "") ?? .the1X1,
                source: self.source ?? "",
                museum: Museum(rawValue: self.museum ?? "") ?? .room1,
                translations: Translations(self.translations ?? [:]),
                colors: self.colors?.compactMap { Color(rawValue: $0) } ?? [],
                keyword: toKeyword()
            )
        case .art:
            let keyword = toKeyword()
            return Art(
                name: self.name ?? "",
                image: self.image ?? "",
                highResTexture: self.highResTexture,
                genuine: self.genuine,
                artCategory: ArtCategory(rawValue: self.artCategory ?? "") .unsafelyUnwrapped,
                buy: Int(self.buy),
                sell: Int(self.sell),
                size: Size(rawValue: self.size ?? "") ?? .the1X1,
                source: self.source ?? "",
                tag: Tag(rawValue: keyword[.tag]?.first ?? "") ?? .picture,
                unlocked: self.unlocked,
                translations: Translations(self.translations ?? [:]),
                colors: self.colors?.compactMap { Color(rawValue: $0) } ?? [],
                concepts: self.concepts?.compactMap { Concept(rawValue: $0) } ?? [],
                keyword: keyword
            )
        }
    }
}

extension Hemispheres {
    
    func toDictionary() -> [String: [String: Any]] {
        [
            "north": [
                "time": [north.time],
                "months": [north.months],
                "monthsArray": [north.monthsArray]
            ],
            "south": [
                "time": [north.time],
                "months": [north.months],
                "monthsArray": [north.monthsArray]
            ]
        ]
    }

    init(_ dictionary: [String: [String: Any]]) {
        self.init(
            north: EmergenceInfo(
                time: dictionary["north"]?["time"] as? [String] ?? [],
                months: dictionary["north"]?["months"] as? [String] ?? [],
                monthsArray: dictionary["north"]?["monthsArray"] as? [Int] ?? []
            ),
            south: EmergenceInfo(
                time: dictionary["south"]?["time"] as? [String] ?? [],
                months: dictionary["south"]?["months"] as? [String] ?? [],
                monthsArray: dictionary["south"]?["monthsArray"] as? [Int] ?? []
            )
        )
    }
}

extension Translations {
    
    func toDictionary() -> [String: String] {
        return [
            "eUde" : eUde,
            "eUen" : eUen,
            "eUit" : eUit,
            "eUnl" : eUnl,
            "eUru" : eUru,
            "eUfr" : eUfr,
            "eUes" : eUes,
            "uSen" : uSen,
            "uSfr" : uSfr,
            "uSes" : uSes,
            "jPja" : jPja,
            "kRko" : kRko,
            "tWzh" : tWzh,
            "cNzh" : cNzh
        ]
    }

    init(_ dictionary: [String: String]) {
        self.init(
            eUde: dictionary["eUde"] ?? "",
            eUen: dictionary["eUen"] ?? "",
            eUit: dictionary["eUit"] ?? "",
            eUnl: dictionary["eUnl"] ?? "",
            eUru: dictionary["eUru"] ?? "",
            eUfr: dictionary["eUfr"] ?? "",
            eUes: dictionary["eUes"] ?? "",
            uSen: dictionary["uSen"] ?? "",
            uSfr: dictionary["uSfr"] ?? "",
            uSes: dictionary["uSes"] ?? "",
            jPja: dictionary["jPja"] ?? "",
            kRko: dictionary["kRko"] ?? "",
            tWzh: dictionary["tWzh"] ?? "",
            cNzh: dictionary["cNzh"] ?? ""
        )
    }
}

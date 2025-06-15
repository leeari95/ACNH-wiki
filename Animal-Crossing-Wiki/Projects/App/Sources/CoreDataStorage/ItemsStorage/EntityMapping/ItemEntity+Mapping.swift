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
        self.name = item.name
        self.category = item.category.rawValue
        self.sell = Int64(item.sell)
        self.translations = item.translations.toDictionary() as NSDictionary
        self.colors = item.colors.map { $0.rawValue } as NSArray
        self.image = item.image
        self.iconImage = item.iconImage
        self.critterpediaImage = item.critterpediaImage
        self.furnitureImage = item.furnitureImage
        self.hemispheres = item.hemispheres?.toDictionary() as NSDictionary?
        self.whereHow = item.whereHow
        self.weather = item.weather?.rawValue
        self.spawnRates = item.spawnRates
        self.catchDifficulty = item.catchDifficulty?.rawValue
        self.vision = item.vision?.rawValue
        self.shadow = item.shadow?.rawValue
        self.movementSpeed = item.movementSpeed?.rawValue
        self.buy = Int64(item.buy ?? -1)
        self.museum = item.museum?.rawValue
        self.highResTexture = item.highResTexture
        self.genuine = item.genuine ?? false
        self.artCategory = item.artCategory?.rawValue
        self.size = item.size?.rawValue
        self.source = item.source
        self.tag = item.tag
        self.concepts = item.concepts?.map { $0.rawValue } as NSArray?
        self.variation = item.variation
        self.bodyTitle = item.bodyTitle
        self.pattern = item.pattern
        self.patternTitle = item.patternTitle
        self.diy = item.diy ?? false
        self.bodyCustomize = item.bodyCustomize ?? false
        self.patternCustomize = item.patternCustomize ?? false
        self.exchangePrice = Int64(item.exchangePrice ?? -1)
        self.exchangeCurrency = item.exchangeCurrency?.rawValue
        self.sources = item.sources as NSArray?
        var notes = item.sourceNotes ?? []
        if let checkedVariants = item.checkedVariants, !checkedVariants.isEmpty {
            do {
                let variantsArray = Array(checkedVariants)
                let jsonData = try JSONSerialization.data(withJSONObject: ["checkedVariants": variantsArray])
                let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
                let checkedVariantsJson = "CHECKED_VARIANTS_JSON:" + jsonString
                notes = [checkedVariantsJson] + notes.filter { !$0.hasPrefix("CHECKED_VARIANTS") }
            } catch {
                let checkedVariantsJson = "CHECKED_VARIANTS:" + checkedVariants.joined(separator: ",")
                notes = [checkedVariantsJson] + notes.filter { !$0.hasPrefix("CHECKED_VARIANTS") }
            }
        } else {
            notes = notes.filter { !$0.hasPrefix("CHECKED_VARIANTS") }
        }
        self.sourceNotes = notes.isEmpty ? nil : notes as NSArray?
        self.seasonEvent = item.seasonEvent
        self.hhaCategory = item.hhaCategory?.rawValue
        self.outdoor = item.outdoor ?? false
        self.speakerType = item.speakerType
        self.lightingType = item.lightingType?.rawValue
        self.catalog = item.catalog?.rawValue
        self.internalId = Int64(item.internalId ?? -1)
        self.set = item.set
        self.series = item.series
        self.recipe = item.recipe?.toDictionary() as NSDictionary?
        self.seriesTranslations = item.seriesTranslations?.toDictionary() as NSDictionary?
        self.variations = item.variations?.compactMap { $0.toDictionary() } as NSArray?
        self.foodPower = Int64(item.foodPower ?? 0)
        self.doorDeco = item.doorDeco ?? false
        self.musicURL = item.musicURL
        self.themes = item.themes as NSArray?
        self.styles = item.styles?.map { $0.rawValue } as NSArray?
        self.keyword = [
            "color": item.colors.map { $0.rawValue },
            "concept": item.concepts?.map { $0.rawValue } ?? [],
            "tag": item.tag.map { [$0] } ?? []
        ] as NSDictionary
    }

    func toKeyword() -> [Keyword: [String]] {
        var keywordList = [Keyword: [String]]()
        (self.keyword as? [String: [String]])?.forEach({ (key: String, value: [String]) in
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
        return Item(
            name: name ?? "",
            category: category,
            sell: Int(sell),
            translations: Translations((translations as? [String: String]) ?? [:]),
            colors: (colors as? [String])?.compactMap { Color(rawValue: $0) } ?? [],
            image: image,
            iconImage: iconImage,
            critterpediaImage: critterpediaImage,
            furnitureImage: furnitureImage,
            hemispheres: Hemispheres((hemispheres as? [String: [String: [Any]]]) ?? [:]),
            whereHow: whereHow,
            weather: Weather(rawValue: weather ?? ""),
            spawnRates: spawnRates,
            catchDifficulty: CatchDifficulty(rawValue: catchDifficulty ?? ""),
            vision: Vision(rawValue: vision ?? ""),
            shadow: Shadow(rawValue: shadow ?? ""),
            movementSpeed: MovementSpeed(rawValue: movementSpeed ?? ""),
            buy: Int(buy),
            museum: Museum(rawValue: museum ?? ""),
            highResTexture: highResTexture,
            genuine: genuine,
            artCategory: ArtCategory(rawValue: artCategory ?? ""),
            size: Size(rawValue: size ?? ""),
            source: source,
            tag: tag,
            concepts: (concepts as? [String])?.compactMap { Concept(rawValue: $0) },
            variation: variation,
            bodyTitle: bodyTitle,
            pattern: pattern,
            patternTitle: patternTitle,
            diy: diy,
            bodyCustomize: bodyCustomize,
            patternCustomize: patternCustomize,
            exchangePrice: Int(exchangePrice),
            exchangeCurrency: ExchangeCurrency(rawValue: exchangeCurrency ?? ""),
            sources: sources as? [String],
            sourceNotes: extractSourceNotes(),
            seasonEvent: seasonEvent,
            hhaCategory: HhaCategory(rawValue: hhaCategory ?? ""),
            outdoor: outdoor,
            speakerType: speakerType,
            lightingType: LightingType(rawValue: lightingType ?? ""),
            catalog: Catalog(rawValue: catalog ?? ""),
            internalId: Int(internalId),
            set: set,
            series: series,
            recipe: RecipeResponseDTO((recipe as? [String: Any]) ?? [:]),
            seriesTranslations: Translations((seriesTranslations as? [String: String]) ?? [:]),
            variations: (variations as? [[String: Any]])?.compactMap { Variant($0) },
            foodPower: Int(foodPower),
            doorDeco: doorDeco,
            musicURL: musicURL,
            themes: themes as? [String],
            styles: (styles as? [String])?.compactMap { Style(rawValue: $0) },
            checkedVariants: extractCheckedVariants()
        )
    }
    
    private func extractSourceNotes() -> [String]? {
        return (sourceNotes as? [String])?.filter { !$0.hasPrefix("CHECKED_VARIANTS") }
    }
    
    private func extractCheckedVariants() -> Set<String>? {
        guard let notes = sourceNotes as? [String] else { return nil }
        
        for note in notes {
            if note.hasPrefix("CHECKED_VARIANTS_JSON:") {
                let jsonString = String(note.dropFirst("CHECKED_VARIANTS_JSON:".count))
                if let jsonData = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let variantsArray = json["checkedVariants"] as? [String] {
                    return Set(variantsArray)
                }
            } else if note.hasPrefix("CHECKED_VARIANTS:") {
                let variantsString = String(note.dropFirst("CHECKED_VARIANTS:".count))
                return Set(variantsString.components(separatedBy: ",").filter { !$0.isEmpty })
            }
        }
        return nil
    }
}

extension Hemispheres {

    func toDictionary() -> [String: [String: [Any]]] {
        [
            "north": [
                "time": north.time,
                "months": north.months,
                "monthsArray": north.monthsArray
            ],
            "south": [
                "time": north.time,
                "months": north.months,
                "monthsArray": north.monthsArray
            ]
        ]
    }

    init(_ dictionary: [String: [String: [Any]]]) {
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
            "eUde": eUde,
            "eUen": eUen,
            "eUit": eUit,
            "eUnl": eUnl,
            "eUru": eUru,
            "eUfr": eUfr,
            "eUes": eUes,
            "uSen": uSen,
            "uSfr": uSfr,
            "uSes": uSes,
            "jPja": jPja,
            "kRko": kRko,
            "tWzh": tWzh,
            "cNzh": cNzh
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

extension RecipeResponseDTO {
    func toDictionary() -> [String: Any] {
        var translations = [String: [String: String]]()
        materialsTranslations.forEach { (key: String, value: Translations?) in
            translations[key] = value?.toDictionary() ?? [:]
        }
        return [
            "name": name,
            "image": image,
            "imageSh": imageSh ?? "",
            "buy": buy,
            "sell": sell ?? 0,
            "exchangePrice": exchangePrice ?? 0,
            "exchangeCurrency": exchangeCurrency?.rawValue ?? "",
            "source": source,
            "sourceNotes": sourceNotes ?? [],
            "seasonEvent": seasonEvent ?? "",
            "seasonEventExclusive": seasonEventExclusive ?? false,
            "versionAdded": versionAdded,
            "unlocked": unlocked,
            "recipesToUnlock": recipesToUnlock,
            "category": category,
            "craftedItemInternalId": craftedItemInternalId,
            "cardColor": cardColor ?? "",
            "diyIconFilename": diyIconFilename,
            "diyIconFilenameSh": diyIconFilenameSh ?? "",
            "serialId": serialId,
            "internalId": internalId,
            "translations": self.translations?.toDictionary() ?? [:],
            "materials": materials,
            "materialsTranslations": translations
        ]
    }

    init(_ dictionary: [String: Any]) {
        var translations = [String: Translations?]()
        (dictionary["materialsTranslations"] as? [String: [String: String]])?.forEach({ (key: String, value: [String: String]) in
            translations[key] = Translations(value)
        })
        self.init(
            name: dictionary["name"] as? String ?? "",
            image: dictionary["image"] as? String ?? "",
            imageSh: dictionary["imageSh"] as? String,
            buy: dictionary["buy"] as? Int ?? -1,
            sell: dictionary["sell"] as? Int,
            exchangePrice: dictionary["exchangePrice"] as? Int,
            exchangeCurrency: ExchangeCurrency(rawValue: dictionary["exchangeCurrency"] as? String ?? ""),
            source: dictionary["source"] as? [String] ?? [],
            sourceNotes: dictionary["sourceNotes"] as? [String],
            seasonEvent: dictionary["seasonEvent"] as? String,
            seasonEventExclusive: dictionary["seasonEventExclusive"] as? Bool,
            versionAdded: dictionary["versionAdded"] as? String ?? "",
            unlocked: dictionary["unlocked"] as? Bool ?? false,
            recipesToUnlock: dictionary["recipesToUnlock"] as? Int ?? 0,
            category: dictionary["category"] as? String ?? "",
            craftedItemInternalId: dictionary["craftedItemInternalId"] as? Int ?? 0,
            cardColor: dictionary["cardColor"] as? String ?? "",
            diyIconFilename: dictionary["diyIconFilename"] as? String ?? "",
            diyIconFilenameSh: dictionary["diyIconFilenameSh"] as? String,
            serialId: dictionary["serialId"] as? Int ?? 0,
            internalId: dictionary["internalId"] as? Int ?? 0,
            translations: Translations(dictionary["translations"] as? [String: String] ?? [:]),
            materials: dictionary["materials"] as? [String: Int] ?? [:],
            materialsTranslations: translations
        )
    }
}

extension Variant {
    func toDictionary() -> [String: Any] {
        return [
            "image": image,
            "variation": variation ?? "",
            "pattern": pattern ?? "",
            "patternTitle": patternTitle ?? "",
            "kitType": kitType?.rawValue ?? "",
            "cyrusCustomizePrice": cyrusCustomizePrice,
            "surface": surface ?? false,
            "exchangePrice": exchangePrice ?? -1,
            "exchangeCurrency": exchangeCurrency?.rawValue ?? "",
            "seasonEvent": seasonEvent ?? "",
            "seasonEventExclusive": seasonEventExclusive ?? false,
            "hhaCategory": hhaCategory?.rawValue ?? "",
            "filename": filename,
            "variantId": variantId,
            "internalId": internalId,
            "variantTranslations": variantTranslations?.toDictionary() ?? [:],
            "colors": colors?.map { $0.rawValue } ?? [],
            "concepts": concepts?.map { $0.rawValue } ?? [],
            "patternTranslations": patternTranslations?.toDictionary() ?? [:]
        ]
    }

    init(_ dictionary: [String: Any]) {
        self.init(
            image: dictionary["image"] as? String ?? "",
            variation: dictionary["variation"] as? String ?? "",
            pattern: dictionary["pattern"] as? String ?? "",
            patternTitle: dictionary["patternTitle"] as? String ?? "",
            kitType: Kit(rawValue: dictionary["kitType"] as? String ?? ""),
            cyrusCustomizePrice: dictionary["cyrusCustomizePrice"] as? Int ?? -1,
            surface: dictionary["surface"] as? Bool ?? false,
            exchangePrice: dictionary["exchangePrice"] as? Int,
            exchangeCurrency: ExchangeCurrency(rawValue: dictionary["exchangeCurrency"] as? String ?? ""),
            seasonEvent: dictionary["seasonEvent"] as? String,
            seasonEventExclusive: dictionary["seasonEventExclusive"] as? Bool,
            hhaCategory: HhaCategory(rawValue: dictionary["hhaCategory"] as? String ?? ""),
            filename: dictionary["filename"] as? String ?? "",
            variantId: dictionary["variantId"] as? String ?? "",
            internalId: dictionary["internalId"] as? Int ?? -1,
            variantTranslations: Translations(dictionary["variantTranslations"] as? [String: String] ?? [:]),
            colors: (dictionary["colors"] as? [String] ?? []).compactMap { Color(rawValue: $0) },
            concepts: (dictionary["concepts"] as? [String] ?? []).compactMap { Concept(rawValue: $0) },
            patternTranslations: Translations(dictionary["patternTranslations"] as? [String: String] ?? [:]),
            soundType: SoundType(rawValue: dictionary["soundType"] as? String ?? "")
        )
    }
}

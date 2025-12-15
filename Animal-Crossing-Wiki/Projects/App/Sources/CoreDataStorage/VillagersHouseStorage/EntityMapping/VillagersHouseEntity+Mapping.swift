//
//  VillagersHouseEntity+Mapping.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation
import CoreData

extension VillagersHouseEntity {

    convenience init(_ villager: Villager, context: NSManagedObjectContext) {
        self.init(context: context)
        self.birthday = villager.birthday
        self.catchphrase = villager.catchphrase
        self.catchphrases = villager.catchphrases.toDictionary() as NSDictionary
        self.colors = villager.colors.map { $0.rawValue } as NSArray
        self.diyWorkbench = villager.diyWorkbench
        self.favoriteSong = villager.favoriteSong
        self.furnitureList = villager.furnitureList as NSArray
        self.furnitureNameList = villager.furnitureNameList as NSArray
        self.gender = villager.gender.rawValue
        self.hobby = villager.hobby.rawValue
        self.houseImage = villager.houseImage
        self.iconImage = villager.iconImage
        self.kitchenEquipment = villager.kitchenEquipment
        self.name = villager.name
        self.personality = villager.personality.rawValue
        self.photoImage = villager.photoImage
        self.species = villager.species.rawValue
        self.styles = villager.styles.map { $0.rawValue } as NSArray
        self.subtype = villager.subtype.rawValue
        self.translations = villager.translations.toDictionary() as NSDictionary

    }

    func toDomain() -> Villager {
        return Villager(
            name: self.name ?? "",
            iconImage: self.iconImage ?? "",
            photoImage: self.photoImage ?? "",
            houseImage: self.houseImage,
            species: Specie(rawValue: self.species ?? "") ?? .cat,
            gender: Gender(rawValue: self.gender ?? "") ?? .male,
            personality: Personality(rawValue: self.personality ?? "") ?? .normal,
            subtype: Subtype(rawValue: self.subtype ?? "") ?? .a,
            hobby: Hobby(rawValue: self.hobby ?? "") ?? .education,
            birthday: self.birthday ?? "",
            catchphrase: self.catchphrase ?? "",
            favoriteSong: self.favoriteSong ?? "",
            furnitureList: (self.furnitureList as? [Int]) ?? [],
            furnitureNameList: (self.furnitureNameList as? [String]) ?? [],
            diyWorkbench: self.diyWorkbench ?? "",
            kitchenEquipment: self.kitchenEquipment ?? "",
            catchphrases: Translations((self.catchphrases as? [String: String]) ?? [:]),
            translations: Translations((self.translations as? [String: String]) ?? [:]),
            styles: ((self.styles as? [String]) ?? []).compactMap { Style(rawValue: $0) },
            colors: ((self.colors as? [String]) ?? []).compactMap { Color(rawValue: $0) }
        )
    }
}

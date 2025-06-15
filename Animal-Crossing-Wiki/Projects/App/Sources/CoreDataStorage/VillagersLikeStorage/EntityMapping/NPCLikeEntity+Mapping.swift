//
//  VillagersLikeEntity+Mapping.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation
import CoreData

extension NPCLikeEntity {
    convenience init(_ npc: NPC, context: NSManagedObjectContext) {
        self.init(context: context)

        self.birthday = npc.birthday
        self.gender = npc.gender.rawValue
        self.genderAsia = npc.genderAsia.rawValue
        self.species = npc.species
        self.iconImage = npc.iconImage
        self.photoImage = npc.photoImage
        self.name = npc.name
        self.appearanceLocation = npc.appearanceLocation?.compactMap({ item -> Data? in
            try? JSONEncoder().encode(item)
        }) as NSArray?
        self.translations = npc.translations.toDictionary() as NSDictionary
    }

    func toDomain(appearanceLocation: [AppearanceLocation]?) -> NPC {
        return NPC(
            name: self.name ?? "",
            iconImage: self.iconImage ?? "",
            photoImage: self.photoImage ?? "",
            gender: Gender(rawValue: self.gender ?? "") ?? .male,
            genderAsia: Gender(rawValue: self.gender ?? "") ?? .male,
            species: self.species ?? "",
            birthday: self.birthday ?? "",
            appearanceLocation: appearanceLocation ?? [],
            translations: Translations((self.translations as? [String: String]) ?? [:])
        )
    }
}

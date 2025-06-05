//
//  ReactionsResponseDTO.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/11/23.
//

import Foundation
import ACNHCore

struct ReactionsResponseDTO: Decodable {
    let num: Int
    let name: String
    let image: String
    let source: [String]
    let sourceNotes: [String]?
    let seasonEvent: String?
    let seasonEventExclusive: Bool?
    let versionAdded: String
    let iconFilename: String
    let internalId: Int
    let uniqueEntryId: String
    let translations: Translations
}

extension Item {
    init(
        name: String,
        category: Category,
        sell: Int,
        translations: Translations,
        colors: [Color],
        image: String,
        sources: [String],
        sourceNotes: [String]?,
        seasonEvent: String?,
        internalId: Int
    ) {
        self.name = name
        self.category = category
        self.sell = sell
        self.translations = translations
        self.colors = colors
        self.image = image
        self.sources = sources
        self.sourceNotes = sourceNotes
        self.seasonEvent = seasonEvent
        self.internalId = internalId
        self.genuine = true
    }
}

extension ReactionsResponseDTO: DomainConvertible {
    func toDomain() -> Item {
        return Item(
            name: name,
            category: .reactions,
            sell: -1,
            translations: translations,
            colors: [],
            image: image,
            sources: source,
            sourceNotes: sourceNotes,
            seasonEvent: seasonEvent,
            internalId: internalId
        )
    }
}

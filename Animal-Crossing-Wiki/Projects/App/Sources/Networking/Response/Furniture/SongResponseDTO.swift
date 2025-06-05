//
//  SongResponseDTO.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/08/18.
//

import Foundation
import ACNHCore

struct SongResponseDTO: Decodable {
    let name: String
    let framedImage: String?
    let albumImage: String?
    let buy: Int
    let sell: Int?
    let hhaBasePoints: Int
    let size: Size
    let source: [String]
    let sourceNotes: [String]
    let seasonEvent: String?
    let seasonEventExclusive: Bool?
    let catalog: Catalog?
    let versionAdded: String
    let unlocked: Bool
    let filename: String
    let internalId: Int
    let uniqueEntryId: String
    let translations: Translations
    let colors: [Color]
    let musicURL: String?
}

extension SongResponseDTO: DomainConvertible {
    func toDomain() -> Item {
        var sources = ["K.K. concert"]
        var sourceNotes: [String]?
        if buy != -1 {
            sources.append("Nook Shopping Daily Selection")
        } else {
            sourceNotes = ["Hidden song"]
        }
        return Item(
            name: name,
            category: .songs,
            sell: sell ?? -1,
            translations: translations,
            image: albumImage,
            buy: buy,
            sources: sources,
            sourceNotes: sourceNotes,
            musicURL: musicURL ?? ""
        )
    }
}

extension Item {
    init(
        name: String,
        category: Category,
        sell: Int,
        translations: Translations,
        image: String?,
        buy: Int?,
        sources: [String],
        sourceNotes: [String]?,
        musicURL: String
    ) {
        self.name = name
        self.category = category
        self.sell = sell
        self.translations = translations
        self.image = image
        self.buy = buy
        self.sources = sources
        self.sourceNotes = sourceNotes
        self.colors = []
        self.genuine = true
        self.musicURL = musicURL
    }
}

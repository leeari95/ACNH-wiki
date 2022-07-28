//
//  MusicResponseDTO.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/20.
//

import Foundation

struct MusicResponseDTO: Codable {
    let id: Int
    let fileName: String
    let name: MusicTranslations
    let buyPrice: Int?
    let sellPrice: Int
    let isOrderable: Bool
    let musicURL: String
    let imageURL: String

    enum CodingKeys: String, CodingKey {
        case id, name, isOrderable
        case fileName = "file-name"
        case buyPrice = "buy-price"
        case sellPrice = "sell-price"
        case musicURL = "music_uri"
        case imageURL = "image_uri"
    }
}

struct MusicTranslations: Codable {
    let uSen, eUen, eUde, eUes: String
    let uSes, eUfr, uSfr, eUit: String
    let eUnl, cNzh, tWzh, jPja: String
    let kRko, eUru: String

    enum CodingKeys: String, CodingKey {
        case uSen = "name-USen"
        case eUen = "name-EUen"
        case eUde = "name-EUde"
        case eUes = "name-EUes"
        case uSes = "name-USes"
        case eUfr = "name-EUfr"
        case uSfr = "name-USfr"
        case eUit = "name-EUit"
        case eUnl = "name-EUnl"
        case cNzh = "name-CNzh"
        case tWzh = "name-TWzh"
        case jPja = "name-JPja"
        case kRko = "name-KRko"
        case eUru = "name-EUru"
    }
    func toDomain() -> Translations {
        return Translations(
            eUde: self.eUde,
            eUen: self.eUen,
            eUit: self.eUit,
            eUnl: self.eUnl,
            eUru: self.eUru,
            eUfr: self.eUfr,
            eUes: self.eUes,
            uSen: self.uSen,
            uSfr: self.uSfr,
            uSes: self.uSes,
            jPja: self.jPja,
            kRko: self.kRko,
            tWzh: self.tWzh,
            cNzh: self.cNzh
        )
    }
}

extension MusicResponseDTO {
    func toDomain() -> Item {
        var sources = ["K.K. concert"]
        var sourceNotes: [String]?
        if isOrderable {
            sources.append("Nook Shopping Daily Selection")
        } else {
            sourceNotes = ["Hidden song"]
        }
        return Item(
            name: name.uSen,
            category: .songs,
            sell: sellPrice,
            translations: name.toDomain(),
            image: imageURL,
            buy: buyPrice,
            sources: sources,
            sourceNotes: sourceNotes,
            musicURL: musicURL
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

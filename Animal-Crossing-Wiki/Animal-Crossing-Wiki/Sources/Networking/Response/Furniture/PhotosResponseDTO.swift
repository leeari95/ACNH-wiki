//
//  PhotosResponseDTO.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/11/17.
//

import Foundation

struct PhotosResponseDTO: Codable {
    let sourceSheet: String
    let name: String
    let diy: Bool
    let kitCost: Int
    let size: Size
    let versionAdded: String
    let bodyTitle: String
    let buy, sell: Int
    let customize: Bool
    let translations: Translations
    let source: [String]
    let hhaBasePoints: Int
    let unlocked: Bool
    let variations: [Variant]
}

extension PhotosResponseDTO {
    
    func toDomain() -> Item {
        return Item(
            name: name,
            category: .photos,
            sell: sell,
            translations: translations,
            colors: variations.first?.colors ?? [],
            diy: diy,
            size: size,
            image: variations.first?.image ?? "",
            bodyTitle: bodyTitle,
            sources: source,
            bodyCustomize: customize,
            hhaBasePoints: hhaBasePoints,
            variations: variations
        )
    }
}

extension Item {
    init(
        name: String,
        category: Category,
        sell: Int,
        translations: Translations,
        colors: [Color],
        diy: Bool,
        size: Size,
        image: String?,
        bodyTitle: String,
        sources: [String],
        bodyCustomize: Bool,
        hhaBasePoints: Int,
        variations: [Variant]
    ) {
        self.name = name
        self.category = category
        self.sell = sell
        self.translations = translations
        self.colors = colors
        self.diy = diy
        self.size = size
        self.image = image
        self.bodyTitle = bodyTitle
        self.sources = sources
        self.bodyCustomize = bodyCustomize
        self.hhaBasePoints = hhaBasePoints
        self.variations = variations
        self.genuine = true
    }
}

//
//  NPC.swift
//  ACNH-wiki
//
//  Created by Ari on 11/23/24.
//

import Foundation

struct NPC {
    let name: String
    let iconImage: String
    let photoImage: String?
    let gender: Gender
    let genderAsia: Gender
    let species: String
    let birthday: String
    let appearanceLocation: [AppearanceLocation]?
    let translations: Translations
    
    var isRandomVisit: Bool {
        ["C.J.", "Flick", "Redd", "Gulliver", "Gullivarrr", "Label", "Wisp", "Celeste"].contains(name)
    }
    
    var isFixedVisit: Bool {
        ["Saharah", "Kicks", "Leif", "Pascal", "Sable", "K.K.", "Daisy Mae"].contains(name)
    }
}

extension NPC: Identifiable {
    public var id: String { UUID().uuidString }
}

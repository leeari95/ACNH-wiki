//
//  NPC.swift
//  ACNH-wiki
//
//  Created by Ari on 11/23/24.
//

import Foundation

public struct NPC {
    public let name: String
    public let iconImage: String
    public let photoImage: String?
    public let gender: Gender
    public let genderAsia: Gender
    public let species: String
    public let birthday: String
    public let appearanceLocation: [AppearanceLocation]?
    public let translations: Translations
    
    public var isRandomVisit: Bool {
        ["C.J.", "Flick", "Redd", "Gulliver", "Gullivarrr", "Label", "Wisp", "Celeste"].contains(name)
    }
    
    public var isFixedVisit: Bool {
        ["Saharah", "Kicks", "Leif", "Pascal", "Sable", "K.K.", "Daisy Mae"].contains(name)
    }
}

public extension NPC: Identifiable {
    public var id: String { UUID().uuidString }
}

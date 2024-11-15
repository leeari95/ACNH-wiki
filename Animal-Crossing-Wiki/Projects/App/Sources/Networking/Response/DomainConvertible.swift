//
//  DomainConvertible.swift
//  ACNH-wiki
//
//  Created by Ari on 11/15/24.
//

import Foundation

protocol DomainConvertible: Decodable {
    func toDomain() -> Item
}

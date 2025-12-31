//
//  TurnipPriceEntity+Mapping.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation
import CoreData

extension TurnipPriceEntity {

    convenience init(_ turnipPrice: TurnipPrice, context: NSManagedObjectContext) {
        self.init(context: context)
        self.id = turnipPrice.id
        self.weekStartDate = turnipPrice.weekStartDate
        self.buyPrice = Int64(turnipPrice.buyPrice ?? 0)
        self.prices = turnipPrice.prices.map { NSNumber(value: $0 ?? -1) } as NSArray
        self.createdDate = turnipPrice.createdDate
    }

    func toDomain() -> TurnipPrice {
        let pricesArray: [Int?] = (prices as? [NSNumber])?.map { number in
            let value = number.intValue
            return value == -1 ? nil : value
        } ?? Array(repeating: nil, count: 12)

        return TurnipPrice(
            id: id ?? UUID(),
            weekStartDate: weekStartDate ?? Date().startOfWeek,
            buyPrice: buyPrice > 0 ? Int(buyPrice) : nil,
            prices: pricesArray,
            createdDate: createdDate ?? Date()
        )
    }
}

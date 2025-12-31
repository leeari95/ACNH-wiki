//
//  TurnipPriceStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation
import RxSwift

protocol TurnipPriceStorage {

    func fetchCurrentWeekPrice() -> Single<TurnipPrice?>
    func fetchAllPrices() -> Single<[TurnipPrice]>
    func savePrice(_ turnipPrice: TurnipPrice) -> Single<TurnipPrice>
    func updatePrice(_ turnipPrice: TurnipPrice)
    func deletePrice(_ turnipPrice: TurnipPrice) -> Single<TurnipPrice>
}

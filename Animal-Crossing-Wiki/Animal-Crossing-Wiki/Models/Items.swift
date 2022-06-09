//
//  Items.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/08.
//

import Foundation
import OSLog

final class Items {
    static let shared = Items()
    
    private let network: APIProvider = DefaultAPIProvider()
    
    private(set) var villagers: [Villager] = []
    private(set) var categories: [Category: [Item]] = [:]
    private(set) var isLoad = false
    
    init() {
        let group = DispatchGroup()
        group.enter()
        network.requestList(VillagersRequest()) { result in
            switch result {
            case .success(let response):
                let items = response.map { $0.toDomain() }
                self.villagers.append(contentsOf: items)
            case .failure(let error):
                os_log(
                    .error,
                    log: .default,
                    "⛔️ 주민을 가져오는데 실패했습니다.\n에러내용: \(error.localizedDescription)"
                )
            }
            group.leave()
        }
        group.enter()
        network.requestList(BugRequest()) { result in
            switch result {
            case .success(let response):
                let items = response.map { $0.toDomain() }
                self.categories[.bugs] = items
            case .failure(let error):
                os_log(
                    .error,
                    log: .default,
                    "⛔️ 곤충을 가져오는데 실패했습니다.\n에러내용: \(error.localizedDescription)"
                )
            }
            group.leave()
        }
        group.enter()
        network.requestList(FishRequest()) { result in
            switch result {
            case .success(let response):
                let items = response.map { $0.toDomain() }
                self.categories[.fish] = items
            case .failure(let error):
                os_log(
                    .error,
                    log: .default,
                    "⛔️ 물고기를 가져오는데 실패했습니다.\n에러내용: \(error.localizedDescription)"
                )
            }
            group.leave()
        }
        group.enter()
        network.requestList(FossilsRequest()) { result in
            switch result {
            case .success(let response):
                let items = response.map { $0.toDomain() }
                self.categories[.fossils] = items
            case .failure(let error):
                os_log(
                    .error,
                    log: .default,
                    "⛔️ 화석을 가져오는데 실패했습니다.\n에러내용: \(error.localizedDescription)"
                )
            }
            group.leave()
        }
        group.enter()
        network.requestList(ArtRequest()) { result in
            switch result {
            case .success(let response):
                let items = response.map { $0.toDomain() }
                self.categories[.art] = items
            case .failure(let error):
                os_log(
                    .error,
                    log: .default,
                    "⛔️ 미술품을 가져오는데 실패했습니다.\n에러내용: \(error.localizedDescription)"
                )
            }
            group.leave()
        }
        group.notify(queue: .main) {
            self.isLoad = true
        }
    }

}

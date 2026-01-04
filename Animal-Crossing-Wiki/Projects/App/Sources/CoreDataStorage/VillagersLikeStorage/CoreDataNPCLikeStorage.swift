//
//  CoreDataNPCLikeStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation
import RxSwift

final class CoreDataNPCLikeStorage: NPCLikeStorage {

    private let coreDataStorage: CoreDataStorage

    init(coreDataStorage: CoreDataStorage = CoreDataStorage.shared) {
        self.coreDataStorage = coreDataStorage
    }

    func fetch() -> [NPC] {
        let context = coreDataStorage.persistentContainer.viewContext
        var npcs: [NPCLikeEntity] = []
        context.performAndWait {
            let object = try? self.coreDataStorage.getUserCollection(context)
            npcs = object?.npcLike?.allObjects as? [NPCLikeEntity] ?? []
        }
        return npcs.map { object -> NPC in
            var appearanceLocation: [AppearanceLocation] = []
            
            if let dataList = object.appearanceLocation {
                let decodedList = dataList.compactMap { data -> AppearanceLocation? in
                    guard let data = data as? Data else {
                        return nil
                    }
                    return try? JSONDecoder().decode(AppearanceLocation.self, from: data)
                }
                appearanceLocation.append(contentsOf: decodedList)
            }
              
            return object.toDomain(appearanceLocation: appearanceLocation)
        }
        .sorted(by: { $0.translations.localizedName() < $1.translations.localizedName() })
    }

    func update(_ npc: NPC) {
        self.coreDataStorage.performBackgroundTask { context in
            do {
                let object = try self.coreDataStorage.getUserCollection(context)
                let npcs = object.npcLike?.allObjects as? [NPCLikeEntity] ?? []
                if let index = npcs.firstIndex(where: { $0.name == npc.name }) {
                    object.removeFromNpcLike(npcs[index])
                } else {
                    let newNPC = NPCLikeEntity(npc, context: context)
                    object.addToNpcLike(newNPC)
                }
                context.saveContext()
            } catch {
                debugPrint(error)
            }
        }
    }
}

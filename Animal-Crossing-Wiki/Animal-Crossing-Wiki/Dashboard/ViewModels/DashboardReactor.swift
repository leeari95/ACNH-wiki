//
//  DashboardViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/11.
//

import Foundation
import ReactorKit

final class DashboardReactor: Reactor {
    
    enum Menu: String {
        case about = "About"
        case setting = "Setting"
        
        static func transform(localized: String) -> String? {
            switch localized {
            case Menu.about.rawValue.localized: return Menu.about.rawValue
            case Menu.setting.rawValue.localized: return Menu.setting.rawValue
            default: return nil
            }
        }
    }
    
    let initialState: State = State()
    var coordinator: DashboardCoordinator?
    
    init(coordinator: DashboardCoordinator) {
        self.coordinator = coordinator
    }

    enum Action {
        case selected(title: String)
    }
    
    enum Mutation {
        case selected(menu: Menu?)
    }
    
    struct State {}
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .selected(let title):
            let menu = Menu(rawValue: Menu.transform(localized: title) ?? "")
            return Observable.just(Mutation.selected(menu: menu))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        switch mutation {
        case .selected(let menu):
            switch menu {
            case .about:
                self.coordinator?.transition(for: .about)
            case .setting:
                self.coordinator?.transition(for: .setting)
            default: break
            }
        }
        return state
    }
}

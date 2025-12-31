//
//  EventCalendarSectionReactor.swift
//  Animal-Crossing-Wiki
//
//  Created by Claude on 2024/01/01.
//

import Foundation
import ReactorKit

final class EventCalendarSectionReactor: Reactor {

    enum Action {
        case fetch
    }

    enum Mutation {
        case setEvents(_ events: [ACNHEvent])
    }

    struct State {
        var events: [ACNHEvent] = []
    }

    let initialState: State

    init(coordinator: DashboardCoordinator) {
        // coordinator is reserved for future use (e.g., event detail navigation)
        self.initialState = State()
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetch:
            let events = ACNHEvent.eventsForCurrentMonth
            return Observable.just(Mutation.setEvents(events))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setEvents(let events):
            newState.events = events
        }
        return newState
    }
}

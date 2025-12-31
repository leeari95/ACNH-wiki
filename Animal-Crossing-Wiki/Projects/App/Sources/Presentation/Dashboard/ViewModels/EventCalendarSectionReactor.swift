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
        var ongoingEvents: [ACNHEvent] = []
        var upcomingEvents: [ACNHEvent] = []
    }

    let initialState: State
    private let coordinator: DashboardCoordinator

    init(coordinator: DashboardCoordinator) {
        self.coordinator = coordinator
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
            newState.ongoingEvents = events.filter { $0.isOngoing }
            newState.upcomingEvents = events.filter { $0.isUpcoming && !$0.isOngoing }
        }
        return newState
    }
}

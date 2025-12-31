//
//  CurrentCreaturesSectionReactor.swift
//  Animal-Crossing-Wiki
//
//  Created by Claude on 2025/01/01.
//

import Foundation
import ReactorKit
import RxSwift

final class CurrentCreaturesSectionReactor: Reactor {

    enum Action {
        case fetch
        case creatureTapped(index: Int)
        case filterChanged(category: Category?)
    }

    enum Mutation {
        case setCreatures(_ creatures: [Item])
        case setSelectedCategory(_ category: Category?)
        case transition(route: DashboardCoordinator.Route)
    }

    struct State {
        var creatures: [Item] = []
        var filteredCreatures: [Item] = []
        var selectedCategory: Category?

        /// Returns the creatures to display based on the current filter.
        /// Use this property instead of checking selectedCategory manually.
        var displayedCreatures: [Item] {
            selectedCategory == nil ? creatures : filteredCreatures
        }
    }

    let initialState: State = State()
    private var coordinator: DashboardCoordinator?

    init(coordinator: DashboardCoordinator?) {
        self.coordinator = coordinator
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetch:
            return fetchCurrentCreatures()
                .map { Mutation.setCreatures($0) }

        case .creatureTapped(let index):
            guard let creature = currentState.displayedCreatures[safe: index] else {
                return Observable.empty()
            }
            return Observable.just(Mutation.transition(route: .itemDetail(item: creature)))

        case .filterChanged(let category):
            return Observable.just(Mutation.setSelectedCategory(category))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setCreatures(let creatures):
            newState.creatures = creatures
            newState.filteredCreatures = filterCreatures(creatures, by: state.selectedCategory)

        case .setSelectedCategory(let category):
            newState.selectedCategory = category
            newState.filteredCreatures = filterCreatures(state.creatures, by: category)

        case .transition(let route):
            coordinator?.transition(for: route)
        }
        return newState
    }

    private func filterCreatures(_ creatures: [Item], by category: Category?) -> [Item] {
        guard let category = category else {
            return creatures
        }
        return creatures.filter { $0.category == category }
    }

    private func fetchCurrentCreatures() -> Observable<[Item]> {
        return Observable.combineLatest(
            Items.shared.categoryList,
            Items.shared.userInfo.compactMap { $0?.hemisphere }
        )
        .map { [weak self] categories, hemisphere -> [Item] in
            guard let self = self else { return [] }

            let now = Date()
            let currentMonth = Calendar.current.component(.month, from: now)
            let currentHour = Calendar.current.component(.hour, from: now)

            var currentCreatures: [Item] = []

            for category in Category.critters {
                guard let items = categories[category] else { continue }

                let availableItems = items.filter { item in
                    self.isAvailable(item: item, hemisphere: hemisphere, month: currentMonth, hour: currentHour)
                }
                currentCreatures.append(contentsOf: availableItems)
            }

            return currentCreatures.sorted { $0.category < $1.category }
        }
    }

    private func isAvailable(item: Item, hemisphere: Hemisphere, month: Int, hour: Int) -> Bool {
        guard let hemispheres = item.hemispheres else { return false }

        let emergenceInfo: EmergenceInfo
        switch hemisphere {
        case .north:
            emergenceInfo = hemispheres.north
        case .south:
            emergenceInfo = hemispheres.south
        }

        // Check if current month is available
        guard emergenceInfo.monthsArray.contains(month) else {
            return false
        }

        // Check if current hour is available
        return isTimeAvailable(times: emergenceInfo.time, hour: hour)
    }

    private func isTimeAvailable(times: [String], hour: Int) -> Bool {
        for timeRange in times {
            if timeRange.lowercased() == "all day" {
                return true
            }

            // Parse time range like "4 AM - 9 AM" or "4 PM - 9 PM"
            if let range = parseTimeRange(timeRange), isHourInRange(hour: hour, range: range) {
                return true
            }
        }
        return false
    }

    private func parseTimeRange(_ timeRange: String) -> (start: Int, end: Int)? {
        let components = timeRange.components(separatedBy: " – ")
        guard components.count == 2 else {
            // Try with different dash
            let altComponents = timeRange.components(separatedBy: " - ")
            guard altComponents.count == 2 else { return nil }
            return parseStartEnd(altComponents[0], altComponents[1])
        }
        return parseStartEnd(components[0], components[1])
    }

    private func parseStartEnd(_ start: String, _ end: String) -> (start: Int, end: Int)? {
        guard let startHour = parseHour(start),
              let endHour = parseHour(end) else {
            return nil
        }
        return (startHour, endHour)
    }

    private func parseHour(_ timeString: String) -> Int? {
        let trimmed = timeString.trimmingCharacters(in: .whitespaces)
        let isPM = trimmed.lowercased().contains("pm")
        let isAM = trimmed.lowercased().contains("am")

        let numberString = trimmed
            .replacingOccurrences(of: "AM", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "PM", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespaces)

        guard let hour = Int(numberString) else { return nil }

        if isPM && hour != 12 {
            return hour + 12
        } else if isAM && hour == 12 {
            return 0
        }
        return hour
    }

    /// Checks if the given hour falls within the specified time range.
    /// The end time is exclusive (e.g., for "4 AM - 9 AM", 9:00 AM is NOT included).
    /// This matches Animal Crossing's actual behavior where creatures disappear at the end time.
    private func isHourInRange(hour: Int, range: (start: Int, end: Int)) -> Bool {
        if range.start <= range.end {
            return hour >= range.start && hour < range.end
        } else {
            // Overnight range (e.g., 9 PM - 4 AM)
            return hour >= range.start || hour < range.end
        }
    }
}

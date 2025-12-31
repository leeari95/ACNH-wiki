//
//  ACNHEvent.swift
//  Animal-Crossing-Wiki
//
//  Created by Claude on 2024/01/01.
//

import Foundation

struct ACNHEvent: Equatable {
    let id: String
    let name: String
    let iconName: String
    let startDate: EventDate
    let endDate: EventDate?
    let eventType: EventType

    var isOngoing: Bool {
        let calendar = Calendar.current
        let today = Date()
        let currentMonth = calendar.component(.month, from: today)
        let currentDay = calendar.component(.day, from: today)

        if let endDate = endDate {
            // Range event
            if startDate.month == endDate.month {
                // Same month
                return currentMonth == startDate.month &&
                       currentDay >= startDate.day &&
                       currentDay <= endDate.day
            } else if startDate.month < endDate.month {
                // Different months (same year logic)
                if currentMonth == startDate.month {
                    return currentDay >= startDate.day
                } else if currentMonth == endDate.month {
                    return currentDay <= endDate.day
                } else {
                    return currentMonth > startDate.month && currentMonth < endDate.month
                }
            } else {
                // Year wrap (e.g., December to January)
                if currentMonth >= startDate.month {
                    return currentDay >= startDate.day || currentMonth > startDate.month
                } else if currentMonth <= endDate.month {
                    return currentDay <= endDate.day || currentMonth < endDate.month
                }
                return false
            }
        } else {
            // Single day event
            return currentMonth == startDate.month && currentDay == startDate.day
        }
    }

    var isUpcoming: Bool {
        let calendar = Calendar.current
        let today = Date()
        let currentMonth = calendar.component(.month, from: today)
        let currentDay = calendar.component(.day, from: today)

        if currentMonth == startDate.month {
            return currentDay < startDate.day
        }

        // Check if event is in next 30 days
        let daysUntilEvent = daysUntil(month: startDate.month, day: startDate.day, from: today)
        return daysUntilEvent > 0 && daysUntilEvent <= 30
    }

    private func daysUntil(month: Int, day: Int, from date: Date) -> Int {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day

        guard var eventDate = calendar.date(from: components) else { return 0 }

        if eventDate < date {
            components.year = year + 1
            eventDate = calendar.date(from: components) ?? eventDate
        }

        return calendar.dateComponents([.day], from: date, to: eventDate).day ?? 0
    }

    var dateDisplayString: String {
        if let endDate = endDate {
            return "\(startDate.month)/\(startDate.day) - \(endDate.month)/\(endDate.day)"
        } else {
            return "\(startDate.month)/\(startDate.day)"
        }
    }
}

struct EventDate: Equatable {
    let month: Int
    let day: Int

    init(month: Int, day: Int) {
        self.month = month
        self.day = day
    }
}

enum EventType: String, CaseIterable {
    case fishing = "Fishing Tournament"
    case bugOff = "Bug-Off"
    case seasonal = "Seasonal Event"
    case holiday = "Holiday"
    case special = "Special Event"
}

// MARK: - Static Event Data
extension ACNHEvent {

    static var allEvents: [ACNHEvent] {
        return [
            // Fishing Tournaments (2nd Saturday of each month)
            ACNHEvent(
                id: "fishing_tournament_jan",
                name: "Fishing Tournament",
                iconName: "fish.fill",
                startDate: EventDate(month: 1, day: 11),
                endDate: nil,
                eventType: .fishing
            ),
            ACNHEvent(
                id: "fishing_tournament_apr",
                name: "Fishing Tournament",
                iconName: "fish.fill",
                startDate: EventDate(month: 4, day: 12),
                endDate: nil,
                eventType: .fishing
            ),
            ACNHEvent(
                id: "fishing_tournament_jul",
                name: "Fishing Tournament",
                iconName: "fish.fill",
                startDate: EventDate(month: 7, day: 11),
                endDate: nil,
                eventType: .fishing
            ),
            ACNHEvent(
                id: "fishing_tournament_oct",
                name: "Fishing Tournament",
                iconName: "fish.fill",
                startDate: EventDate(month: 10, day: 10),
                endDate: nil,
                eventType: .fishing
            ),

            // Bug-Off (3rd Saturday of summer months)
            ACNHEvent(
                id: "bug_off_jun",
                name: "Bug-Off",
                iconName: "ladybug.fill",
                startDate: EventDate(month: 6, day: 27),
                endDate: nil,
                eventType: .bugOff
            ),
            ACNHEvent(
                id: "bug_off_jul",
                name: "Bug-Off",
                iconName: "ladybug.fill",
                startDate: EventDate(month: 7, day: 25),
                endDate: nil,
                eventType: .bugOff
            ),
            ACNHEvent(
                id: "bug_off_aug",
                name: "Bug-Off",
                iconName: "ladybug.fill",
                startDate: EventDate(month: 8, day: 22),
                endDate: nil,
                eventType: .bugOff
            ),
            ACNHEvent(
                id: "bug_off_sep",
                name: "Bug-Off",
                iconName: "ladybug.fill",
                startDate: EventDate(month: 9, day: 26),
                endDate: nil,
                eventType: .bugOff
            ),

            // Seasonal Events
            ACNHEvent(
                id: "new_years_day",
                name: "New Year's Day",
                iconName: "sparkles",
                startDate: EventDate(month: 1, day: 1),
                endDate: nil,
                eventType: .holiday
            ),
            ACNHEvent(
                id: "new_years_eve",
                name: "Countdown",
                iconName: "clock.fill",
                startDate: EventDate(month: 12, day: 31),
                endDate: nil,
                eventType: .holiday
            ),
            ACNHEvent(
                id: "festivale",
                name: "Festivale",
                iconName: "music.note.list",
                startDate: EventDate(month: 2, day: 15),
                endDate: nil,
                eventType: .seasonal
            ),
            ACNHEvent(
                id: "shamrock_day",
                name: "Shamrock Day",
                iconName: "leaf.fill",
                startDate: EventDate(month: 3, day: 17),
                endDate: nil,
                eventType: .holiday
            ),
            ACNHEvent(
                id: "bunny_day",
                name: "Bunny Day",
                iconName: "hare.fill",
                startDate: EventDate(month: 4, day: 1),
                endDate: EventDate(month: 4, day: 12),
                eventType: .seasonal
            ),
            ACNHEvent(
                id: "earth_day",
                name: "Nature Day",
                iconName: "globe.americas.fill",
                startDate: EventDate(month: 4, day: 23),
                endDate: EventDate(month: 5, day: 4),
                eventType: .seasonal
            ),
            ACNHEvent(
                id: "may_day",
                name: "May Day",
                iconName: "leaf.fill",
                startDate: EventDate(month: 5, day: 1),
                endDate: EventDate(month: 5, day: 7),
                eventType: .seasonal
            ),
            ACNHEvent(
                id: "international_museum_day",
                name: "International Museum Day",
                iconName: "building.columns.fill",
                startDate: EventDate(month: 5, day: 18),
                endDate: EventDate(month: 5, day: 31),
                eventType: .seasonal
            ),
            ACNHEvent(
                id: "wedding_season",
                name: "Wedding Season",
                iconName: "heart.fill",
                startDate: EventDate(month: 6, day: 1),
                endDate: EventDate(month: 6, day: 30),
                eventType: .seasonal
            ),
            ACNHEvent(
                id: "fireworks_show",
                name: "Fireworks Show",
                iconName: "sparkle",
                startDate: EventDate(month: 8, day: 1),
                endDate: EventDate(month: 8, day: 31),
                eventType: .seasonal
            ),
            ACNHEvent(
                id: "halloween",
                name: "Halloween",
                iconName: "theatermasks.fill",
                startDate: EventDate(month: 10, day: 1),
                endDate: EventDate(month: 10, day: 31),
                eventType: .seasonal
            ),
            ACNHEvent(
                id: "turkey_day",
                name: "Turkey Day",
                iconName: "fork.knife",
                startDate: EventDate(month: 11, day: 26),
                endDate: nil,
                eventType: .holiday
            ),
            ACNHEvent(
                id: "toy_day",
                name: "Toy Day",
                iconName: "gift.fill",
                startDate: EventDate(month: 12, day: 24),
                endDate: nil,
                eventType: .holiday
            ),

            // Cherry Blossom Season
            ACNHEvent(
                id: "cherry_blossom_season",
                name: "Cherry Blossom Season",
                iconName: "camera.macro",
                startDate: EventDate(month: 4, day: 1),
                endDate: EventDate(month: 4, day: 10),
                eventType: .seasonal
            ),

            // Mushroom Season
            ACNHEvent(
                id: "mushroom_season",
                name: "Mushroom Season",
                iconName: "leaf.fill",
                startDate: EventDate(month: 11, day: 1),
                endDate: EventDate(month: 11, day: 30),
                eventType: .seasonal
            ),

            // Maple Leaf Season
            ACNHEvent(
                id: "maple_leaf_season",
                name: "Maple Leaf Season",
                iconName: "leaf.fill",
                startDate: EventDate(month: 11, day: 16),
                endDate: EventDate(month: 11, day: 25),
                eventType: .seasonal
            ),

            // Snowflake Season
            ACNHEvent(
                id: "snowflake_season",
                name: "Snowflake Season",
                iconName: "snowflake",
                startDate: EventDate(month: 12, day: 11),
                endDate: EventDate(month: 2, day: 24),
                eventType: .seasonal
            )
        ]
    }

    static var currentAndUpcomingEvents: [ACNHEvent] {
        let sortedEvents = allEvents.sorted { event1, event2 in
            // Ongoing events first
            if event1.isOngoing && !event2.isOngoing {
                return true
            } else if !event1.isOngoing && event2.isOngoing {
                return false
            }

            // Then sort by date
            if event1.startDate.month != event2.startDate.month {
                return event1.startDate.month < event2.startDate.month
            }
            return event1.startDate.day < event2.startDate.day
        }

        return sortedEvents.filter { $0.isOngoing || $0.isUpcoming }
    }

    static var eventsForCurrentMonth: [ACNHEvent] {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())

        return allEvents.filter { event in
            if event.startDate.month == currentMonth {
                return true
            }
            if let endDate = event.endDate {
                if event.startDate.month <= currentMonth && endDate.month >= currentMonth {
                    return true
                }
                // Year wrap case
                if event.startDate.month > endDate.month {
                    return currentMonth >= event.startDate.month || currentMonth <= endDate.month
                }
            }
            return false
        }.sorted { event1, event2 in
            if event1.isOngoing && !event2.isOngoing {
                return true
            } else if !event1.isOngoing && event2.isOngoing {
                return false
            }
            return event1.startDate.day < event2.startDate.day
        }
    }
}

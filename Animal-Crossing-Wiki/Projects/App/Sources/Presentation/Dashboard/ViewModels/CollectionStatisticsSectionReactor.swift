//
//  CollectionStatisticsSectionReactor.swift
//  Animal-Crossing-Wiki
//
//  Created by Claude on 2026/01/01.
//

import Foundation
import ReactorKit

// MARK: - ProgressCalculatable Protocol

protocol ProgressCalculatable {
    var collectedCount: Int { get }
    var totalCount: Int { get }
}

extension ProgressCalculatable {
    var progressRate: Float {
        guard totalCount > 0 else { return 0 }
        return Float(collectedCount) / Float(totalCount)
    }

    var progressPercentage: Int {
        Int(progressRate * 100)
    }
}

// MARK: - CollectionStatisticsSectionReactor

final class CollectionStatisticsSectionReactor: Reactor {

    enum Action {
        case fetch
        case didTapSection
    }

    enum Mutation {
        case setLoadingState(_ isLoading: Bool)
        case setStatistics(_ statistics: [CategoryStatistics])
        case setTotalProgress(_ progress: TotalProgress)
        case setIsEmpty(_ isEmpty: Bool)
    }

    struct CategoryStatistics: Equatable, ProgressCalculatable {
        let category: Category
        let collectedCount: Int
        let totalCount: Int
    }

    struct TotalProgress: Equatable, ProgressCalculatable {
        let collectedCount: Int
        let totalCount: Int

        static var empty: TotalProgress {
            TotalProgress(collectedCount: 0, totalCount: 0)
        }
    }

    struct State {
        var isLoading: Bool = true
        var statistics: [CategoryStatistics] = []
        var totalProgress: TotalProgress = .empty
        var isEmpty: Bool = false
    }

    let initialState: State
    let coordinator: DashboardCoordinator

    init(coordinator: DashboardCoordinator, state: State = State()) {
        self.coordinator = coordinator
        self.initialState = state
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetch:
            let loadingState = Items.shared.isLoading.map { Mutation.setLoadingState($0) }

            let emptyState = Items.shared.count()
                .map { Mutation.setIsEmpty($0.isEmpty) }

            let statistics = Observable.combineLatest(Items.shared.itemList, Items.shared.count())
                .map { [weak self] userItems, itemsCount -> [Mutation] in
                    guard let self = self else { return [] }

                    let categoryStats = self.calculateCategoryStatistics(
                        userItems: userItems,
                        totalCounts: itemsCount
                    )

                    let totalProgress = self.calculateTotalProgress(from: categoryStats)

                    return [
                        .setStatistics(categoryStats),
                        .setTotalProgress(totalProgress)
                    ]
                }
                .flatMap { Observable.from($0) }

            return Observable.merge(loadingState, emptyState, statistics)

        case .didTapSection:
            coordinator.transition(for: .progress)
            return Observable.empty()
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setLoadingState(let isLoading):
            newState.isLoading = isLoading
        case .setStatistics(let statistics):
            newState.statistics = statistics
        case .setTotalProgress(let progress):
            newState.totalProgress = progress
        case .setIsEmpty(let isEmpty):
            newState.isEmpty = isEmpty
        }
        return newState
    }

    private func calculateCategoryStatistics(
        userItems: [Category: [Item]],
        totalCounts: [Category: Int]
    ) -> [CategoryStatistics] {
        return Category.items().compactMap { category in
            let collectedCount = userItems[category]?.count ?? 0
            let totalCount = totalCounts[category] ?? 0

            guard totalCount > 0 else { return nil }

            return CategoryStatistics(
                category: category,
                collectedCount: collectedCount,
                totalCount: totalCount
            )
        }
    }

    private func calculateTotalProgress(from statistics: [CategoryStatistics]) -> TotalProgress {
        let totalCollected = statistics.reduce(0) { $0 + $1.collectedCount }
        let totalItems = statistics.reduce(0) { $0 + $1.totalCount }

        return TotalProgress(
            collectedCount: totalCollected,
            totalCount: totalItems
        )
    }
}

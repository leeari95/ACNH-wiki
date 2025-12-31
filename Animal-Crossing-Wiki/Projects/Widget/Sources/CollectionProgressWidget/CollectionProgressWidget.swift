//
//  CollectionProgressWidget.swift
//  ACNHWidget
//
//  Created by Claude on 2025/01/01.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct CollectionProgressEntry: TimelineEntry {
    let date: Date
    let collections: [SharedDataManager.WidgetCollectionProgress]
    let userName: String
    let islandName: String

    var totalCollected: Int {
        collections.reduce(0) { $0 + $1.collectedCount }
    }

    var totalItems: Int {
        collections.reduce(0) { $0 + $1.totalCount }
    }

    var overallProgress: Double {
        guard totalItems > 0 else { return 0 }
        return Double(totalCollected) / Double(totalItems)
    }
}

// MARK: - Timeline Provider

struct CollectionProgressProvider: TimelineProvider {
    typealias Entry = CollectionProgressEntry

    func placeholder(in context: Context) -> CollectionProgressEntry {
        CollectionProgressEntry(
            date: Date(),
            collections: SharedDataManager.sampleCollectionProgress,
            userName: "Player",
            islandName: "Island"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CollectionProgressEntry) -> Void) {
        let entry = CollectionProgressEntry(
            date: Date(),
            collections: SharedDataManager.shared.loadCollectionProgress(),
            userName: SharedDataManager.shared.loadUserName(),
            islandName: SharedDataManager.shared.loadIslandName()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CollectionProgressEntry>) -> Void) {
        let currentDate = Date()
        let collections = SharedDataManager.shared.loadCollectionProgress()
        let userName = SharedDataManager.shared.loadUserName()
        let islandName = SharedDataManager.shared.loadIslandName()

        let entry = CollectionProgressEntry(
            date: currentDate,
            collections: collections,
            userName: userName,
            islandName: islandName
        )

        // 1시간마다 타임라인 갱신
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Views

struct CollectionProgressWidgetEntryView: View {
    var entry: CollectionProgressProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallCollectionProgressView(entry: entry)
        case .systemMedium:
            MediumCollectionProgressView(entry: entry)
        case .systemLarge:
            LargeCollectionProgressView(entry: entry)
        default:
            SmallCollectionProgressView(entry: entry)
        }
    }
}

// MARK: - Small Widget View

struct SmallCollectionProgressView: View {
    let entry: CollectionProgressEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)
                Text("Collection")
                    .font(.caption)
                    .fontWeight(.semibold)
            }

            Spacer()

            // Overall Progress Ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: entry.overallProgress)
                    .stroke(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(Int(entry.overallProgress * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
            .frame(width: 80, height: 80)
            .frame(maxWidth: .infinity)

            Spacer()

            // Stats
            Text("\(entry.totalCollected)/\(entry.totalItems)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Medium Widget View

struct MediumCollectionProgressView: View {
    let entry: CollectionProgressEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left: Overall Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.green)
                    Text("Collection")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 6)

                    Circle()
                        .trim(from: 0, to: entry.overallProgress)
                        .stroke(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(Int(entry.overallProgress * 100))%")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
                .frame(width: 60, height: 60)
                .frame(maxWidth: .infinity)

                Spacer()
            }
            .frame(maxWidth: 100)

            // Right: Category Progress
            VStack(alignment: .leading, spacing: 6) {
                ForEach(entry.collections.prefix(5)) { collection in
                    CollectionRowView(collection: collection)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Large Widget View

struct LargeCollectionProgressView: View {
    let entry: CollectionProgressEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Museum Collection")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("\(entry.userName) - \(entry.islandName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Overall Progress Badge
                VStack(spacing: 2) {
                    Text("\(Int(entry.overallProgress * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Complete")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Progress Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(entry.collections) { collection in
                    LargeCollectionCardView(collection: collection)
                }
            }

            Spacer()

            // Footer Stats
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                Text("Total: \(entry.totalCollected) / \(entry.totalItems) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Collection Row Views

struct CollectionRowView: View {
    let collection: SharedDataManager.WidgetCollectionProgress

    var body: some View {
        HStack(spacing: 8) {
            // Category Icon (placeholder - 실제로는 앱 에셋 사용)
            Circle()
                .fill(categoryColor)
                .frame(width: 20, height: 20)
                .overlay(
                    Image(systemName: categoryIcon)
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                )

            Text(collection.categoryName)
                .font(.caption2)
                .lineLimit(1)

            Spacer()

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.3))

                    RoundedRectangle(cornerRadius: 2)
                        .fill(categoryColor)
                        .frame(width: geometry.size.width * collection.progress)
                }
            }
            .frame(width: 40, height: 4)

            Text(collection.percentageText)
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)
        }
    }

    private var categoryColor: Color {
        switch collection.categoryName {
        case "Fishes": return .blue
        case "Bugs": return .orange
        case "Sea Creatures": return .cyan
        case "Fossils": return .brown
        case "Art": return .purple
        default: return .green
        }
    }

    private var categoryIcon: String {
        switch collection.categoryName {
        case "Fishes": return "drop.fill"
        case "Bugs": return "ant.fill"
        case "Sea Creatures": return "tortoise.fill"
        case "Fossils": return "leaf.fill"
        case "Art": return "paintpalette.fill"
        default: return "star.fill"
        }
    }
}

struct LargeCollectionCardView: View {
    let collection: SharedDataManager.WidgetCollectionProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(categoryColor)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: categoryIcon)
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    )

                Text(collection.categoryName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Spacer()
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [categoryColor, categoryColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * collection.progress)
                }
            }
            .frame(height: 8)

            HStack {
                Text(collection.progressText)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Text(collection.percentageText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(categoryColor)
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }

    private var categoryColor: Color {
        switch collection.categoryName {
        case "Fishes": return .blue
        case "Bugs": return .orange
        case "Sea Creatures": return .cyan
        case "Fossils": return .brown
        case "Art": return .purple
        default: return .green
        }
    }

    private var categoryIcon: String {
        switch collection.categoryName {
        case "Fishes": return "drop.fill"
        case "Bugs": return "ant.fill"
        case "Sea Creatures": return "tortoise.fill"
        case "Fossils": return "leaf.fill"
        case "Art": return "paintpalette.fill"
        default: return "star.fill"
        }
    }
}

// MARK: - Widget Configuration

struct CollectionProgressWidget: Widget {
    let kind: String = "CollectionProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CollectionProgressProvider()) { entry in
            CollectionProgressWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Collection Progress")
        .description("Track your museum collection progress at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    CollectionProgressWidget()
} timeline: {
    CollectionProgressEntry(
        date: Date(),
        collections: SharedDataManager.sampleCollectionProgress,
        userName: "Player",
        islandName: "Paradise"
    )
}

#Preview(as: .systemMedium) {
    CollectionProgressWidget()
} timeline: {
    CollectionProgressEntry(
        date: Date(),
        collections: SharedDataManager.sampleCollectionProgress,
        userName: "Player",
        islandName: "Paradise"
    )
}

#Preview(as: .systemLarge) {
    CollectionProgressWidget()
} timeline: {
    CollectionProgressEntry(
        date: Date(),
        collections: SharedDataManager.sampleCollectionProgress,
        userName: "Player",
        islandName: "Paradise"
    )
}

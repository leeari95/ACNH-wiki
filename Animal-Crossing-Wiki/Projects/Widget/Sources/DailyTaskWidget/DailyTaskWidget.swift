//
//  DailyTaskWidget.swift
//  ACNHWidget
//
//  Created by Claude on 2025/01/01.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct DailyTaskEntry: TimelineEntry {
    let date: Date
    let tasks: [SharedDataManager.WidgetDailyTask]
    let islandName: String

    var completedCount: Int {
        tasks.filter { $0.isCompleted }.count
    }

    var totalCount: Int {
        tasks.count
    }

    var allCompleted: Bool {
        completedCount == totalCount
    }
}

// MARK: - Timeline Provider

struct DailyTaskProvider: TimelineProvider {
    typealias Entry = DailyTaskEntry

    func placeholder(in context: Context) -> DailyTaskEntry {
        DailyTaskEntry(
            date: Date(),
            tasks: SharedDataManager.sampleDailyTasks,
            islandName: "Island"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyTaskEntry) -> Void) {
        let entry = DailyTaskEntry(
            date: Date(),
            tasks: SharedDataManager.shared.loadDailyTasks(),
            islandName: SharedDataManager.shared.loadIslandName()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyTaskEntry>) -> Void) {
        let currentDate = Date()
        let tasks = SharedDataManager.shared.loadDailyTasks()
        let islandName = SharedDataManager.shared.loadIslandName()

        let entry = DailyTaskEntry(
            date: currentDate,
            tasks: tasks,
            islandName: islandName
        )

        // 자정에 타임라인 갱신 (일일 할일 리셋)
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: currentDate)!)

        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }
}

// MARK: - Widget Views

struct DailyTaskWidgetEntryView: View {
    var entry: DailyTaskProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallDailyTaskView(entry: entry)
        case .systemMedium:
            MediumDailyTaskView(entry: entry)
        case .systemLarge:
            LargeDailyTaskView(entry: entry)
        default:
            SmallDailyTaskView(entry: entry)
        }
    }
}

// MARK: - Small Widget View

struct SmallDailyTaskView: View {
    let entry: DailyTaskEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
                Text("Daily Tasks")
                    .font(.caption)
                    .fontWeight(.semibold)
            }

            Spacer()

            // Progress Circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: progressValue)
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progressValue)

                VStack(spacing: 2) {
                    Text("\(entry.completedCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("of \(entry.totalCount)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 80, height: 80)
            .frame(maxWidth: .infinity)

            Spacer()

            // Status Text
            Text(statusText)
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var progressValue: CGFloat {
        guard entry.totalCount > 0 else { return 0 }
        return CGFloat(entry.completedCount) / CGFloat(entry.totalCount)
    }

    private var progressColor: Color {
        if entry.allCompleted {
            return .green
        } else if progressValue > 0.5 {
            return .orange
        } else {
            return .accentColor
        }
    }

    private var statusText: String {
        if entry.allCompleted {
            return "All tasks completed!"
        } else {
            return "\(entry.totalCount - entry.completedCount) tasks remaining"
        }
    }
}

// MARK: - Medium Widget View

struct MediumDailyTaskView: View {
    let entry: DailyTaskEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left: Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                    Text("Daily Tasks")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 6)

                    Circle()
                        .trim(from: 0, to: progressValue)
                        .stroke(progressColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(entry.completedCount)/\(entry.totalCount)")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
                .frame(width: 60, height: 60)
                .frame(maxWidth: .infinity)

                Spacer()
            }
            .frame(maxWidth: 100)

            // Right: Task List
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(entry.tasks.prefix(5))) { task in
                    TaskRowView(task: task)
                }

                if entry.tasks.count > 5 {
                    Text("+\(entry.tasks.count - 5) more")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var progressValue: CGFloat {
        guard entry.totalCount > 0 else { return 0 }
        return CGFloat(entry.completedCount) / CGFloat(entry.totalCount)
    }

    private var progressColor: Color {
        if entry.allCompleted {
            return .green
        } else if progressValue > 0.5 {
            return .orange
        } else {
            return .accentColor
        }
    }
}

// MARK: - Large Widget View

struct LargeDailyTaskView: View {
    let entry: DailyTaskEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Tasks")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(entry.islandName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Progress Badge
                Text("\(entry.completedCount)/\(entry.totalCount)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(progressColor.opacity(0.2))
                    .foregroundColor(progressColor)
                    .clipShape(Capsule())
            }

            Divider()

            // Task List
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(entry.tasks) { task in
                    LargeTaskRowView(task: task)
                }
            }

            Spacer()

            // Footer
            if entry.allCompleted {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("Great job! All tasks completed!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var progressColor: Color {
        if entry.allCompleted {
            return .green
        } else if CGFloat(entry.completedCount) / CGFloat(entry.totalCount) > 0.5 {
            return .orange
        } else {
            return .accentColor
        }
    }
}

// MARK: - Task Row Views

struct TaskRowView: View {
    let task: SharedDataManager.WidgetDailyTask

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? .green : .gray)
                .font(.caption)

            Text(task.name)
                .font(.caption2)
                .lineLimit(1)
                .foregroundColor(task.isCompleted ? .secondary : .primary)

            Spacer()

            Text(task.progressText)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct LargeTaskRowView: View {
    let task: SharedDataManager.WidgetDailyTask

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? .green : .gray)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.name)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)

                Text(task.progressText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Widget Configuration

struct DailyTaskWidget: Widget {
    let kind: String = "DailyTaskWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyTaskProvider()) { entry in
            DailyTaskWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Tasks")
        .description("Track your daily Animal Crossing tasks at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    DailyTaskWidget()
} timeline: {
    DailyTaskEntry(
        date: Date(),
        tasks: SharedDataManager.sampleDailyTasks,
        islandName: "Paradise"
    )
}

#Preview(as: .systemMedium) {
    DailyTaskWidget()
} timeline: {
    DailyTaskEntry(
        date: Date(),
        tasks: SharedDataManager.sampleDailyTasks,
        islandName: "Paradise"
    )
}

#Preview(as: .systemLarge) {
    DailyTaskWidget()
} timeline: {
    DailyTaskEntry(
        date: Date(),
        tasks: SharedDataManager.sampleDailyTasks,
        islandName: "Paradise"
    )
}

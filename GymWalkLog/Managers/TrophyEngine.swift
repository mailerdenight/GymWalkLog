import Foundation

enum TrophyCategory: String, CaseIterable, Identifiable {
    case personalRecords
    case monthlyDistance
    case streaks

    var id: String { rawValue }

    var title: String {
        switch self {
        case .personalRecords:
            return "個人記録"
        case .monthlyDistance:
            return "今月の走行距離"
        case .streaks:
            return "連続記録"
        }
    }
}

enum TrophyStyle {
    case sunshine
    case bronze
    case silver
    case gold
    case platinum
    case streak
}

enum TrophyGlyph {
    case longestDistance
    case longestTime
    case fastest(distanceKm: Double)
    case monthlyDistance(Int)
    case streakCount(Int, unit: TrophyStreakUnit)
    case weeklyFrequency(Int)
}

enum TrophyStreakUnit {
    case days
    case weeks
    case months
}

struct TrophyDefinition: Identifiable {
    let id: String
    let category: TrophyCategory
    let title: String
    let subtitle: String?
    let style: TrophyStyle
    let glyph: TrophyGlyph
}

struct TrophyAwardState: Identifiable {
    let definition: TrophyDefinition
    let achieved: Bool
    let achievedDate: Date?
    let achievementCount: Int
    let valueText: String?
    let linkedRecordID: UUID?
    let focusMonthDate: Date?

    var id: String { definition.id }
}

enum TrophyEngine {
    static func sections(from records: [WorkoutRecord]) -> [(category: TrophyCategory, trophies: [TrophyAwardState])] {
        let allDefinitions = definitions
        return TrophyCategory.allCases.map { category in
            let trophies = allDefinitions
                .filter { $0.category == category }
                .map { state(for: $0, records: records) }
            return (category, trophies)
        }
    }

    private static let definitions: [TrophyDefinition] = [
        TrophyDefinition(
            id: "longest_distance",
            category: .personalRecords,
            title: "最長距離",
            subtitle: nil,
            style: .sunshine,
            glyph: .longestDistance
        ),
        TrophyDefinition(
            id: "longest_time",
            category: .personalRecords,
            title: "最長時間",
            subtitle: nil,
            style: .sunshine,
            glyph: .longestTime
        ),
        TrophyDefinition(
            id: "fastest_1k",
            category: .personalRecords,
            title: "1KM最速記録",
            subtitle: nil,
            style: .sunshine,
            glyph: .fastest(distanceKm: 1)
        ),
        TrophyDefinition(
            id: "fastest_5k",
            category: .personalRecords,
            title: "5KM最速記録",
            subtitle: nil,
            style: .sunshine,
            glyph: .fastest(distanceKm: 5)
        ),
        TrophyDefinition(
            id: "fastest_10k",
            category: .personalRecords,
            title: "10KM最速記録",
            subtitle: nil,
            style: .sunshine,
            glyph: .fastest(distanceKm: 10)
        ),
        TrophyDefinition(
            id: "monthly_24k",
            category: .monthlyDistance,
            title: "ブロンズ",
            subtitle: nil,
            style: .bronze,
            glyph: .monthlyDistance(24)
        ),
        TrophyDefinition(
            id: "monthly_40k",
            category: .monthlyDistance,
            title: "シルバー",
            subtitle: nil,
            style: .silver,
            glyph: .monthlyDistance(40)
        ),
        TrophyDefinition(
            id: "monthly_80k",
            category: .monthlyDistance,
            title: "ゴールド",
            subtitle: nil,
            style: .gold,
            glyph: .monthlyDistance(80)
        ),
        TrophyDefinition(
            id: "monthly_160k",
            category: .monthlyDistance,
            title: "プラチナ",
            subtitle: nil,
            style: .platinum,
            glyph: .monthlyDistance(160)
        ),
        TrophyDefinition(
            id: "streak_3_days",
            category: .streaks,
            title: "3日連続",
            subtitle: nil,
            style: .streak,
            glyph: .streakCount(3, unit: .days)
        ),
        TrophyDefinition(
            id: "streak_7_days",
            category: .streaks,
            title: "7日連続",
            subtitle: nil,
            style: .streak,
            glyph: .streakCount(7, unit: .days)
        ),
        TrophyDefinition(
            id: "streak_3_weeks",
            category: .streaks,
            title: "3週連続ラン",
            subtitle: nil,
            style: .streak,
            glyph: .streakCount(3, unit: .weeks)
        ),
        TrophyDefinition(
            id: "streak_3_months",
            category: .streaks,
            title: "3か月連続ラン",
            subtitle: nil,
            style: .streak,
            glyph: .streakCount(3, unit: .months)
        ),
        TrophyDefinition(
            id: "weekly_3x",
            category: .streaks,
            title: "週に3回ラン",
            subtitle: nil,
            style: .streak,
            glyph: .weeklyFrequency(3)
        ),
        TrophyDefinition(
            id: "weekly_5x",
            category: .streaks,
            title: "週に5回ラン",
            subtitle: nil,
            style: .streak,
            glyph: .weeklyFrequency(5)
        ),
        TrophyDefinition(
            id: "weekly_7x",
            category: .streaks,
            title: "週に7回ラン",
            subtitle: nil,
            style: .streak,
            glyph: .weeklyFrequency(7)
        )
    ]

    private static func state(for definition: TrophyDefinition, records: [WorkoutRecord]) -> TrophyAwardState {
        switch definition.glyph {
        case .longestDistance:
            guard let record = records.max(by: { lhs, rhs in lhs.distanceKm < rhs.distanceKm }),
                  record.distanceKm > 0 else {
                return TrophyAwardState(definition: definition, achieved: false, achievedDate: nil, achievementCount: 0, valueText: nil, linkedRecordID: nil, focusMonthDate: nil)
            }
            return TrophyAwardState(
                definition: definition,
                achieved: true,
                achievedDate: record.date,
                achievementCount: 1,
                valueText: String(format: "%.2f km", record.distanceKm),
                linkedRecordID: record.id,
                focusMonthDate: record.date
            )

        case .longestTime:
            guard let record = records.max(by: { lhs, rhs in lhs.durationSeconds < rhs.durationSeconds }),
                  record.durationSeconds > 0 else {
                return TrophyAwardState(definition: definition, achieved: false, achievedDate: nil, achievementCount: 0, valueText: nil, linkedRecordID: nil, focusMonthDate: nil)
            }
            return TrophyAwardState(
                definition: definition,
                achieved: true,
                achievedDate: record.date,
                achievementCount: 1,
                valueText: record.durationFormatted,
                linkedRecordID: record.id,
                focusMonthDate: record.date
            )

        case .fastest(let distanceKm):
            return fastestState(for: definition, targetDistanceKm: distanceKm, records: records)

        case .monthlyDistance(let threshold):
            return monthlyDistanceState(for: definition, thresholdKm: Double(threshold), records: records)

        case .streakCount(let threshold, let unit):
            return streakState(for: definition, threshold: threshold, unit: unit, records: records)

        case .weeklyFrequency(let threshold):
            return weeklyFrequencyState(for: definition, threshold: threshold, records: records)
        }
    }

    private static func fastestState(
        for definition: TrophyDefinition,
        targetDistanceKm: Double,
        records: [WorkoutRecord]
    ) -> TrophyAwardState {
        let candidates = records.compactMap { record -> (record: WorkoutRecord, seconds: Int)? in
            guard record.distanceKm >= targetDistanceKm, record.durationSeconds > 0 else { return nil }
            let seconds = Int((Double(record.durationSeconds) * targetDistanceKm / record.distanceKm).rounded())
            return (record, seconds)
        }
        guard let best = candidates.min(by: { $0.seconds < $1.seconds }) else {
            return TrophyAwardState(definition: definition, achieved: false, achievedDate: nil, achievementCount: 0, valueText: nil, linkedRecordID: nil, focusMonthDate: nil)
        }
        return TrophyAwardState(
            definition: definition,
            achieved: true,
            achievedDate: best.record.date,
            achievementCount: 1,
            valueText: formatClock(best.seconds),
            linkedRecordID: best.record.id,
            focusMonthDate: best.record.date
        )
    }

    private static func monthlyDistanceState(
        for definition: TrophyDefinition,
        thresholdKm: Double,
        records: [WorkoutRecord]
    ) -> TrophyAwardState {
        let months = monthlyDistanceSummaries(records: records)
        let achievedMonths = months.filter { $0.distanceKm >= thresholdKm }
        return TrophyAwardState(
            definition: definition,
            achieved: !achievedMonths.isEmpty,
            achievedDate: achievedMonths.last?.monthStart,
            achievementCount: achievedMonths.count,
            valueText: nil,
            linkedRecordID: nil,
            focusMonthDate: achievedMonths.last?.monthStart
        )
    }

    private static func streakState(
        for definition: TrophyDefinition,
        threshold: Int,
        unit: TrophyStreakUnit,
        records: [WorkoutRecord]
    ) -> TrophyAwardState {
        switch unit {
        case .days:
            let streaks = consecutiveDailyStreaks(records: records)
            let matches = streaks.filter { $0.length >= threshold }
            return TrophyAwardState(
                definition: definition,
                achieved: !matches.isEmpty,
                achievedDate: matches.last?.endDate,
                achievementCount: matches.count,
                valueText: nil,
                linkedRecordID: nil,
                focusMonthDate: matches.last?.endDate
            )
        case .weeks:
            let streaks = consecutivePeriodStreaks(records: records, component: .weekOfYear)
            let matches = streaks.filter { $0.length >= threshold }
            return TrophyAwardState(
                definition: definition,
                achieved: !matches.isEmpty,
                achievedDate: matches.last?.endDate,
                achievementCount: matches.count,
                valueText: nil,
                linkedRecordID: nil,
                focusMonthDate: matches.last?.endDate
            )
        case .months:
            let streaks = consecutivePeriodStreaks(records: records, component: .month)
            let matches = streaks.filter { $0.length >= threshold }
            return TrophyAwardState(
                definition: definition,
                achieved: !matches.isEmpty,
                achievedDate: matches.last?.endDate,
                achievementCount: matches.count,
                valueText: nil,
                linkedRecordID: nil,
                focusMonthDate: matches.last?.endDate
            )
        }
    }

    private static func weeklyFrequencyState(
        for definition: TrophyDefinition,
        threshold: Int,
        records: [WorkoutRecord]
    ) -> TrophyAwardState {
        let weeks = weeklyCounts(records: records)
        let matches = weeks.filter { $0.count >= threshold }
        return TrophyAwardState(
            definition: definition,
            achieved: !matches.isEmpty,
            achievedDate: matches.last?.weekStart,
            achievementCount: matches.count,
            valueText: nil,
            linkedRecordID: nil,
            focusMonthDate: matches.last?.weekStart
        )
    }

    private static func monthlyDistanceSummaries(records: [WorkoutRecord]) -> [(monthStart: Date, distanceKm: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: records) { record in
            calendar.date(from: calendar.dateComponents([.year, .month], from: record.date)) ?? calendar.startOfDay(for: record.date)
        }
        return grouped
            .map { (monthStart: $0.key, distanceKm: $0.value.reduce(0) { $0 + $1.distanceKm }) }
            .sorted { $0.monthStart < $1.monthStart }
    }

    private static func weeklyCounts(records: [WorkoutRecord]) -> [(weekStart: Date, count: Int)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: records) { record in
            calendar.dateInterval(of: .weekOfYear, for: record.date)?.start ?? calendar.startOfDay(for: record.date)
        }
        return grouped
            .map { (weekStart: $0.key, count: Set($0.value.map { calendar.startOfDay(for: $0.date) }).count) }
            .sorted { $0.weekStart < $1.weekStart }
    }

    private static func consecutiveDailyStreaks(records: [WorkoutRecord]) -> [(length: Int, endDate: Date)] {
        let calendar = Calendar.current
        let dates = Array(Set(records.map { calendar.startOfDay(for: $0.date) })).sorted()
        guard !dates.isEmpty else { return [] }

        var results: [(length: Int, endDate: Date)] = []
        var currentLength = 1
        var currentEnd = dates[0]

        for index in 1..<dates.count {
            let diff = calendar.dateComponents([.day], from: dates[index - 1], to: dates[index]).day ?? 0
            if diff == 1 {
                currentLength += 1
            } else {
                results.append((length: currentLength, endDate: currentEnd))
                currentLength = 1
            }
            currentEnd = dates[index]
        }
        results.append((length: currentLength, endDate: currentEnd))
        return results
    }

    private static func consecutivePeriodStreaks(
        records: [WorkoutRecord],
        component: Calendar.Component
    ) -> [(length: Int, endDate: Date)] {
        let calendar = Calendar.current
        let periodStarts: [Date] = Array(
            Set(records.map { record in
                switch component {
                case .weekOfYear:
                    return calendar.dateInterval(of: .weekOfYear, for: record.date)?.start ?? calendar.startOfDay(for: record.date)
                case .month:
                    return calendar.date(from: calendar.dateComponents([.year, .month], from: record.date)) ?? calendar.startOfDay(for: record.date)
                default:
                    return calendar.startOfDay(for: record.date)
                }
            })
        ).sorted()

        guard !periodStarts.isEmpty else { return [] }

        var results: [(length: Int, endDate: Date)] = []
        var currentLength = 1
        var currentEnd = periodStarts[0]

        for index in 1..<periodStarts.count {
            let nextExpected: Date?
            switch component {
            case .weekOfYear:
                nextExpected = calendar.date(byAdding: .weekOfYear, value: 1, to: periodStarts[index - 1])
            case .month:
                nextExpected = calendar.date(byAdding: .month, value: 1, to: periodStarts[index - 1])
            default:
                nextExpected = nil
            }

            if nextExpected == periodStarts[index] {
                currentLength += 1
            } else {
                results.append((length: currentLength, endDate: currentEnd))
                currentLength = 1
            }
            currentEnd = periodStarts[index]
        }

        results.append((length: currentLength, endDate: currentEnd))
        return results
    }

    private static func formatClock(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

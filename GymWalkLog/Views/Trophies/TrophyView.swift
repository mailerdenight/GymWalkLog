import SwiftUI
import SwiftData

struct TrophyView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Query(sort: \WorkoutRecord.date, order: .reverse) private var records: [WorkoutRecord]
    @State private var activeDestination: TrophyDestination?

    var theme: AppTheme { appSettings.theme }

    private let columns = [
        GridItem(.flexible(), spacing: 18),
        GridItem(.flexible(), spacing: 18),
        GridItem(.flexible(), spacing: 18)
    ]

    private var sections: [(category: TrophyCategory, trophies: [TrophyAwardState])] {
        TrophyEngine.sections(from: records)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                summaryCard

                ForEach(sections, id: \.category.id) { section in
                    VStack(alignment: .leading, spacing: 16) {
                        Text(section.category.title)
                            .font(.title3)
                            .fontWeight(.bold)

                        LazyVGrid(columns: columns, alignment: .leading, spacing: 20) {
                            ForEach(section.trophies) { trophy in
                                TrophyCardView(trophy: trophy, theme: theme) {
                                    openTrophy(trophy)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(theme.backgroundColor.ignoresSafeArea())
        .navigationTitle("トロフィー")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeDestination) { destination in
            switch destination {
            case .record(let recordID):
                if let record = records.first(where: { $0.id == recordID }) {
                    NavigationStack {
                        RecordDetailView(record: record)
                    }
                } else {
                    ContentUnavailableView("記録が見つかりません", systemImage: "rosette")
                }
            case .calendar(let monthDate):
                CalendarFullView(initialMonth: monthDate)
            }
        }
    }

    private var summaryCard: some View {
        let unlocked = sections.flatMap(\.trophies).filter(\.achieved).count
        let total = sections.flatMap(\.trophies).count

        return HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [theme.primaryColor.opacity(0.18), theme.secondaryColor.opacity(0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 74, height: 74)
                TrophyBadgeIcon(
                    glyph: .longestDistance,
                    style: .sunshine,
                    achieved: true,
                    theme: theme
                )
                .frame(width: 54, height: 54)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("積み上げた記録をバッジに")
                    .font(.headline)
                Text("\(unlocked) / \(total) 個を獲得")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("距離・継続・自己ベストから自動で更新されます。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(theme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private func openTrophy(_ trophy: TrophyAwardState) {
        guard trophy.achieved else { return }
        if let recordID = trophy.linkedRecordID {
            activeDestination = .record(recordID: recordID)
        } else if let monthDate = trophy.focusMonthDate {
            activeDestination = .calendar(monthDate: monthDate)
        }
    }
}

private struct TrophyCardView: View {
    let trophy: TrophyAwardState
    let theme: AppTheme
    let action: () -> Void

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy/MM/dd"
        return f
    }()

    private var dateText: String {
        guard let achievedDate = trophy.achievedDate else { return "" }
        return Self.dateFormatter.string(from: achievedDate)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                TrophyBadgeIcon(
                    glyph: trophy.definition.glyph,
                    style: trophy.definition.style,
                    achieved: trophy.achieved,
                    theme: theme
                )
                .frame(width: 88, height: 88)
                .opacity(trophy.achieved ? 1 : 0.26)
                .shadow(color: trophy.achieved ? .black.opacity(0.08) : .clear, radius: 6, y: 4)

                VStack(spacing: 1) {
                    if trophy.achieved {
                        Text(dateText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("未獲得")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(trophy.definition.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.85)

                    if let valueText = trophy.valueText {
                        Text(valueText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if trophy.achieved {
                        Text("\(trophy.achievementCount)回")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if trophy.achieved {
                        Text(trophy.linkedRecordID != nil ? "記録を見る" : "月を見る")
                            .font(.caption2)
                            .foregroundColor(theme.primaryColor)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.plain)
        .disabled(!trophy.achieved)
    }
}

private enum TrophyDestination: Identifiable {
    case record(recordID: UUID)
    case calendar(monthDate: Date)

    var id: String {
        switch self {
        case .record(let recordID):
            return "record-\(recordID.uuidString)"
        case .calendar(let monthDate):
            return "calendar-\(monthDate.timeIntervalSince1970)"
        }
    }
}

struct TrophyBadgeIcon: View {
    let glyph: TrophyGlyph
    let style: TrophyStyle
    let achieved: Bool
    let theme: AppTheme

    private var palette: TrophyPalette {
        guard achieved else {
            return TrophyPalette(stroke: Color(hex: "D5D7DD"), fill: Color(hex: "F5F6F8"), accent: Color.white)
        }
        switch style {
        case .sunshine:
            return TrophyPalette(stroke: Color(hex: "151515"), fill: Color(hex: "FFD93D"), accent: Color(hex: "2F2500"))
        case .bronze:
            return TrophyPalette(stroke: Color(hex: "4E352A"), fill: Color(hex: "B8805A"), accent: Color(hex: "E4BC9C"))
        case .silver:
            return TrophyPalette(stroke: Color(hex: "4C525A"), fill: Color(hex: "B9C0C8"), accent: Color(hex: "F0F2F5"))
        case .gold:
            return TrophyPalette(stroke: Color(hex: "4F4317"), fill: Color(hex: "D1B35A"), accent: Color(hex: "FFF1A8"))
        case .platinum:
            return TrophyPalette(stroke: Color(hex: "444B63"), fill: Color(hex: "D8DDF4"), accent: Color(hex: "FFFFFF"))
        case .streak:
            return TrophyPalette(stroke: Color(hex: "1A1A1A"), fill: Color(hex: "222126"), accent: Color(hex: "D3FF39"))
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)

            ZStack {
                TrophyShieldShape()
                    .fill(palette.fill)
                TrophyShieldShape()
                    .stroke(palette.stroke, lineWidth: size * 0.08)

                TrophyShieldShape()
                    .stroke(palette.accent.opacity(0.95), lineWidth: size * 0.03)
                    .scaleEffect(0.74)

                glyphView(size: size)
                    .foregroundStyle(palette.accent)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private func glyphView(size: CGFloat) -> some View {
        switch glyph {
        case .longestDistance:
            Image(systemName: "arrow.up.forward")
                .font(.system(size: size * 0.34, weight: .bold))
        case .longestTime:
            Image(systemName: "stopwatch")
                .font(.system(size: size * 0.32, weight: .bold))
        case .fastest(let distanceKm):
            Text(distanceLabel(distanceKm))
                .font(.system(size: size * 0.28, weight: .black, design: .rounded))
                .offset(y: -size * 0.05)
        case .monthlyDistance(let threshold):
            VStack(spacing: size * 0.02) {
                Text("\(threshold)K")
                    .font(.system(size: size * 0.24, weight: .black, design: .rounded))
                Text("MONTH")
                    .font(.system(size: size * 0.08, weight: .bold, design: .rounded))
                    .tracking(size * 0.01)
            }
            .offset(y: -size * 0.03)
        case .streakCount(let count, let unit):
            HStack(spacing: size * 0.02) {
                Text("\(count)")
                    .font(.system(size: size * 0.34, weight: .black, design: .rounded))
                if unit == .months {
                    Text("M")
                        .font(.system(size: size * 0.24, weight: .black, design: .rounded))
                } else if unit == .weeks {
                    Text("W")
                        .font(.system(size: size * 0.24, weight: .black, design: .rounded))
                }
            }
            .overlay(alignment: .leading) {
                Image(systemName: "arrow.right")
                    .font(.system(size: size * 0.11, weight: .black))
                    .offset(x: -size * 0.20, y: size * 0.01)
            }
        case .weeklyFrequency(let count):
            HStack(spacing: size * 0.02) {
                Text("\(count)")
                    .font(.system(size: size * 0.34, weight: .black, design: .rounded))
                Text("X")
                    .font(.system(size: size * 0.23, weight: .black, design: .rounded))
            }
            .overlay(alignment: .leading) {
                Image(systemName: "arrow.right")
                    .font(.system(size: size * 0.11, weight: .black))
                    .offset(x: -size * 0.20, y: size * 0.01)
            }
        }
    }

    private func distanceLabel(_ km: Double) -> String {
        if km == floor(km) {
            return "\(Int(km))K"
        }
        return String(format: "%.1fK", km)
    }
}

struct TrophyPalette {
    let stroke: Color
    let fill: Color
    let accent: Color
}

struct TrophyShieldShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width * 0.20, y: height * 0.12))
        path.addLine(to: CGPoint(x: width * 0.80, y: height * 0.12))
        path.addLine(to: CGPoint(x: width * 0.80, y: height * 0.70))
        path.addLine(to: CGPoint(x: width * 0.50, y: height * 0.92))
        path.addLine(to: CGPoint(x: width * 0.20, y: height * 0.70))
        path.closeSubpath()
        return path
    }
}

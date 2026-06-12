import SwiftUI

enum AppTheme: String, CaseIterable {
    case natural = "natural"
    case blossom = "blossom"
    case sky = "sky"
    case sunshine = "sunshine"

    var displayName: String {
        switch self {
        case .natural:  return "フォレスト"
        case .blossom:  return "ブロッサム"
        case .sky:      return "オーシャン"
        case .sunshine: return "サンシャイン"
        }
    }

    var primaryColor: Color {
        switch self {
        case .natural:  return Color(hex: "4A7C59")
        case .blossom:  return Color(hex: "C4687A")
        case .sky:      return Color(hex: "4A7FA8")
        case .sunshine: return Color(hex: "C09020")
        }
    }

    var secondaryColor: Color {
        switch self {
        case .natural:  return Color(hex: "6B9E7A")
        case .blossom:  return Color(hex: "E8A8B8")
        case .sky:      return Color(hex: "7AAFD0")
        case .sunshine: return Color(hex: "E0BC6A")
        }
    }

    var accentColor: Color {
        switch self {
        case .natural:  return Color(hex: "2D5A3D")
        case .blossom:  return Color(hex: "8B4558")
        case .sky:      return Color(hex: "2B5F84")
        case .sunshine: return Color(hex: "8B6C10")
        }
    }

    var backgroundColor: Color {
        Color(UIColor { tc in
            if tc.userInterfaceStyle == .dark {
                return UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
            }
            switch self {
            case .natural:  return UIColor(red: 0.96, green: 0.96, blue: 0.94, alpha: 1)
            case .blossom:  return UIColor(red: 0.99, green: 0.96, blue: 0.97, alpha: 1)
            case .sky:      return UIColor(red: 0.94, green: 0.97, blue: 0.99, alpha: 1)
            case .sunshine: return UIColor(red: 0.99, green: 0.98, blue: 0.93, alpha: 1)
            }
        })
    }

    var cardColor: Color {
        Color(UIColor { tc in
            tc.userInterfaceStyle == .dark
                ? UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
                : .white
        })
    }

    var calendarDotColor: Color {
        switch self {
        case .natural:  return Color(hex: "4A7C59")
        case .blossom:  return Color(hex: "E8A8B8")
        case .sky:      return Color(hex: "4A7FA8")
        case .sunshine: return Color(hex: "C09020")
        }
    }

    var buttonTextColor: Color { Color.white }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

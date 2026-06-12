import Vision
import UIKit
import CoreGraphics

struct OCRResult {
    var distanceKm: Double?
    var distanceBox: CGRect?
    var durationSeconds: Int?
    var durationBox: CGRect?
    var caloriesKcal: Double?
    var caloriesBox: CGRect?
    var recognizedTextCount: Int = 0

    var isEmpty: Bool {
        distanceKm == nil && durationSeconds == nil && caloriesKcal == nil
    }
}

private struct TextCandidate {
    let text: String
    let box: CGRect     // Vision座標系（正規化）
}

enum PhotoOCRManager {

    static func extractWorkoutData(from image: UIImage,
                                   profile: TreadmillProfile = .load()) async -> OCRResult {
        guard let cgImage = image.cgImage else { return OCRResult() }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US", "ja-JP"]
        request.usesLanguageCorrection = false

        try? VNImageRequestHandler(
            cgImage: cgImage,
            orientation: CGImagePropertyOrientation(image.imageOrientation),
            options: [:]
        ).perform([request])

        let all: [TextCandidate] = request.results?.compactMap { obs in
            guard let t = obs.topCandidates(1).first?.string else { return nil }
            return TextCandidate(text: normalizedOCRText(t), box: obs.boundingBox)
        } ?? []

        var result = OCRResult()
        result.recognizedTextCount = all.count

        // プロファイルの既知領域に絞った候補（学習済みの場合）
        let priorityDist = all.filter { profile.isInKnownRegion($0.box, for: .distance) }
        let priorityDur  = all.filter { profile.isInKnownRegion($0.box, for: .duration) }
        let priorityCal  = all.filter { profile.isInKnownRegion($0.box, for: .calories) }

        // 距離：学習済み領域 → 全体 の順に試みる
        if let r = extractDistance(from: priorityDist.isEmpty ? all : priorityDist) {
            result.distanceKm  = r.value
            result.distanceBox = r.box
        }
        // 時間
        if let r = extractDuration(from: priorityDur.isEmpty ? all : priorityDur) {
            result.durationSeconds = r.value
            result.durationBox     = r.box
        } else if !priorityDur.isEmpty, let r = extractDuration(from: all) {
            result.durationSeconds = r.value
            result.durationBox     = r.box
        }
        // カロリー
        if let r = extractCalories(from: priorityCal.isEmpty ? all : priorityCal) {
            result.caloriesKcal = r.value
            result.caloriesBox  = r.box
        } else if !priorityCal.isEmpty, let r = extractCalories(from: all) {
            result.caloriesKcal = r.value
            result.caloriesBox  = r.box
        }

        return result
    }

    // MARK: - 距離

    private static func extractDistance(from candidates: [TextCandidate]) -> (value: Double, box: CGRect)? {
        let patterns = [
            "(?:dist(?:ance)?|距離|miles?)\\.?\\s*[:：]?\\s*([0-9]{1,2}(?:[.,][0-9]{1,3})?)\\s*(?:[kK][mM]|miles?)?",
            "([0-9]{1,2}(?:[.,][0-9]{1,3})?)\\s*[kK][mM]",
            "([0-9]{1,2}(?:[.,][0-9]{1,3})?)\\s*(?:miles?)",
            "([0-9]{1,2}(?:[.,][0-9]{1,2})?)\\s*[kK](?![cC])",
            "([0-9]{1,2}(?:[.,][0-9]{1,3})?)\\s*(?:dist(?:ance)?|距離|miles?)\\.?",
        ]
        for c in candidates {
            for p in patterns {
                if let v = firstDouble(in: c.text, pattern: p) { return (v, c.box) }
            }
        }
        if let matched = extractLabeledDistanceAcrossCandidates(from: candidates) {
            return matched
        }
        // 単独の小数（距離ラベルが別行の場合）
        for c in candidates {
            if let v = firstDouble(in: c.text.trimmingCharacters(in: .whitespaces),
                                   pattern: "^([0-9]{1,2}[.,][0-9]{1,3})$"), v < 50 {
                return (v, c.box)
            }
        }
        return nil
    }

    // MARK: - 時間

    private static func extractDuration(from candidates: [TextCandidate]) -> (value: Int, box: CGRect)? {
        for c in candidates {
            // HH:MM:SS
            if let m = capture(pattern: "([0-9]{1,2}):([0-9]{2}):([0-9]{2})", in: c.text),
               m.count == 3 {
                let secs = (Int(m[0]) ?? 0) * 3600 + (Int(m[1]) ?? 0) * 60 + (Int(m[2]) ?? 0)
                return (secs, c.box)
            }
        }
        for c in candidates {
            // MM:SS
            if let m = capture(pattern: "([0-9]{1,2}):([0-9]{2})", in: c.text),
               m.count == 2, let min = Int(m[0]), min < 60 {
                return (min * 60 + (Int(m[1]) ?? 0), c.box)
            }
        }
        for c in candidates {
            // 30'00" / 30 00 のように認識されるトレッドミル表示
            if let m = capture(pattern: "^([0-9]{1,2})\\s*['′分 ]\\s*([0-9]{2})\\s*(?:[\"″秒])?$", in: c.text),
               m.count == 2, let min = Int(m[0]), min < 60 {
                return (min * 60 + (Int(m[1]) ?? 0), c.box)
            }
        }
        if let matched = extractLabeledDurationAcrossCandidates(from: candidates) {
            return matched
        }
        return nil
    }

    // MARK: - カロリー

    private static func extractCalories(from candidates: [TextCandidate]) -> (value: Double, box: CGRect)? {
        let patterns = [
            ("([0-9]+)\\s*[kK][cC][aA][lL]", 1.0),
            ("([0-9]+)\\s*[cC][aA][lL]\\.?s?", 1.0),
            ("([0-9]+)\\s*[kK][jJ]",            0.239),   // kJ → kcal
            ("(?:ca[1lI]ories|ca[1lI]orie|ca[1lI]s|kca[1lI]|ca[1lI]\\.?|カロリー)\\s*[:：]?\\s*([0-9]{1,4})", 1.0),
        ]
        for c in candidates {
            for (p, ratio) in patterns {
                if let v = firstDouble(in: c.text, pattern: p) {
                    return ((v * ratio).rounded(), c.box)
                }
            }
        }
        if let matched = extractLabeledCaloriesAcrossCandidates(from: candidates) {
            return matched
        }
        // 単独の3〜4桁整数
        for c in candidates {
            if let v = firstDouble(in: c.text.trimmingCharacters(in: .whitespaces),
                                   pattern: "^([0-9]{3,4})$"), v <= 2000 {
                return (v, c.box)
            }
        }
        return nil
    }

    // MARK: - 正規表現ユーティリティ

    private static func firstDouble(in text: String, pattern: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let m = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text))
        else { return nil }
        let range = m.numberOfRanges > 1
            ? Range(m.range(at: 1), in: text)
            : Range(m.range, in: text)
        guard let r = range else { return nil }
        return Double(text[r].replacingOccurrences(of: ",", with: "."))
    }

    private static func capture(pattern: String, in text: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let m = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text))
        else { return nil }
        return (1..<m.numberOfRanges).compactMap { i in
            Range(m.range(at: i), in: text).map { String(text[$0]) }
        }
    }

    private static func extractLabeledCaloriesAcrossCandidates(from candidates: [TextCandidate]) -> (value: Double, box: CGRect)? {
        for label in candidates {
            guard matches(pattern: "(?:ca[1lI]ories|ca[1lI]orie|ca[1lI]s|kca[1lI]|ca[1lI]\\.?)|カロリー", in: label.text) else { continue }

            let nearbyNumbers = candidates.compactMap { candidate -> (value: Double, box: CGRect)? in
                guard candidate.box != label.box else { return nil }
                guard isLikelySameReadingRow(label: label.box, value: candidate.box) else { return nil }
                guard isNearby(label: label.box, value: candidate.box) else { return nil }
                guard let value = firstDouble(
                    in: candidate.text.trimmingCharacters(in: .whitespaces),
                    pattern: "^([0-9]{2,4})(?:\\s*[kK]?[cC]?[aA]?[lL1I]?)?$"
                ) else { return nil }
                guard value <= 2000 else { return nil }
                return (value, candidate.box)
            }

            if let best = nearbyNumbers.min(by: { horizontalDistance(from: label.box, to: $0.box) < horizontalDistance(from: label.box, to: $1.box) }) {
                return (best.value.rounded(), union(label.box, best.box))
            }
        }

        return nil
    }

    private static func extractLabeledDistanceAcrossCandidates(from candidates: [TextCandidate]) -> (value: Double, box: CGRect)? {
        let labelPattern = "(?:^|[^a-zA-Z])(?:dist(?:ance)?|距離|km|miles?)(?:[^a-zA-Z]|$)"

        for label in candidates {
            guard matches(pattern: labelPattern, in: label.text) else { continue }

            let nearbyValues = candidates.compactMap { candidate -> (value: Double, box: CGRect)? in
                guard candidate.box != label.box else { return nil }
                guard isLikelySameReadingRow(label: label.box, value: candidate.box) else { return nil }
                guard isNearby(label: label.box, value: candidate.box) else { return nil }
                guard let value = firstDouble(
                    in: candidate.text.trimmingCharacters(in: .whitespaces),
                    pattern: "^([0-9]{1,2}(?:[.,][0-9]{1,3})?)(?:\\s*(?:[kK][mM]?|miles?))?$"
                ) else { return nil }
                guard value > 0, value < 50 else { return nil }
                return (value, candidate.box)
            }

            if let best = nearbyValues.min(by: { horizontalDistance(from: label.box, to: $0.box) < horizontalDistance(from: label.box, to: $1.box) }) {
                return (best.value, union(label.box, best.box))
            }
        }

        return nil
    }

    private static func extractLabeledDurationAcrossCandidates(from candidates: [TextCandidate]) -> (value: Int, box: CGRect)? {
        let labelPattern = "(?:^|[^a-zA-Z])(?:time|ti[1lI]me|時間|timer)(?:[^a-zA-Z]|$)"

        for label in candidates {
            guard matches(pattern: labelPattern, in: label.text) else { continue }

            let nearbyValues = candidates.compactMap { candidate -> (value: Int, box: CGRect)? in
                guard candidate.box != label.box else { return nil }
                guard isLikelySameReadingRow(label: label.box, value: candidate.box) else { return nil }
                guard isNearby(label: label.box, value: candidate.box) else { return nil }

                if let m = capture(pattern: "^([0-9]{1,2}):([0-9]{2}):([0-9]{2})$", in: candidate.text),
                   m.count == 3 {
                    let secs = (Int(m[0]) ?? 0) * 3600 + (Int(m[1]) ?? 0) * 60 + (Int(m[2]) ?? 0)
                    return (secs, candidate.box)
                }
                if let m = capture(pattern: "^([0-9]{1,2}):([0-9]{2})$", in: candidate.text),
                   m.count == 2,
                   let min = Int(m[0]),
                   min < 60 {
                    return (min * 60 + (Int(m[1]) ?? 0), candidate.box)
                }
                if let m = capture(pattern: "^([0-9]{1,2})\\s*['′分 ]\\s*([0-9]{2})\\s*(?:[\"″秒])?$", in: candidate.text),
                   m.count == 2,
                   let min = Int(m[0]),
                   min < 60 {
                    return (min * 60 + (Int(m[1]) ?? 0), candidate.box)
                }
                return nil
            }

            if let best = nearbyValues.min(by: { horizontalDistance(from: label.box, to: $0.box) < horizontalDistance(from: label.box, to: $1.box) }) {
                return (best.value, union(label.box, best.box))
            }
        }

        return nil
    }

    private static func matches(pattern: String, in text: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return false
        }
        return regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }

    private static func isLikelySameReadingRow(label: CGRect, value: CGRect) -> Bool {
        let labelMidY = label.midY
        let valueMidY = value.midY
        let verticalAllowance = max(label.height, value.height) * 1.4
        return abs(labelMidY - valueMidY) <= verticalAllowance
    }

    private static func isNearby(label: CGRect, value: CGRect) -> Bool {
        horizontalDistance(from: label, to: value) <= max(label.width, value.width) * 6.0
    }

    private static func horizontalDistance(from lhs: CGRect, to rhs: CGRect) -> CGFloat {
        if lhs.maxX < rhs.minX { return rhs.minX - lhs.maxX }
        if rhs.maxX < lhs.minX { return lhs.minX - rhs.maxX }
        return 0
    }

    private static func union(_ lhs: CGRect, _ rhs: CGRect) -> CGRect {
        CGRect(
            x: min(lhs.minX, rhs.minX),
            y: min(lhs.minY, rhs.minY),
            width: max(lhs.maxX, rhs.maxX) - min(lhs.minX, rhs.minX),
            height: max(lhs.maxY, rhs.maxY) - min(lhs.minY, rhs.minY)
        )
    }

    private static func normalizedOCRText(_ text: String) -> String {
        let halfWidth = text.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? text
        return halfWidth
            .replacingOccurrences(of: "：", with: ":")
            .replacingOccurrences(of: "O", with: "0")
            .replacingOccurrences(of: "o", with: "0")
            .replacingOccurrences(of: "l", with: "1")
            .replacingOccurrences(of: "｜", with: "1")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

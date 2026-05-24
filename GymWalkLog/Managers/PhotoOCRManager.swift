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

        try? VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])

        let all: [TextCandidate] = request.results?.compactMap { obs in
            guard let t = obs.topCandidates(1).first?.string else { return nil }
            return TextCandidate(text: t, box: obs.boundingBox)
        } ?? []

        var result = OCRResult()

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
            "([0-9]+[.,][0-9]+)\\s*[kK][mM]",
            "([0-9]+[.,][0-9]+)\\s*[kK](?![cC])",
        ]
        for c in candidates {
            for p in patterns {
                if let v = firstDouble(in: c.text, pattern: p) { return (v, c.box) }
            }
        }
        // 単独の少数（距離ラベルが別行の場合）
        for c in candidates {
            if let v = firstDouble(in: c.text.trimmingCharacters(in: .whitespaces),
                                   pattern: "^([0-9]+[.,][0-9]{2})$"), v < 50 {
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
        return nil
    }

    // MARK: - カロリー

    private static func extractCalories(from candidates: [TextCandidate]) -> (value: Double, box: CGRect)? {
        let patterns = [
            ("([0-9]+)\\s*[kK][cC][aA][lL]", 1.0),
            ("([0-9]+)\\s*[cC][aA][lL]",       1.0),
            ("([0-9]+)\\s*[kK][jJ]",            0.239),   // kJ → kcal
        ]
        for c in candidates {
            for (p, ratio) in patterns {
                if let v = firstDouble(in: c.text, pattern: p) {
                    return ((v * ratio).rounded(), c.box)
                }
            }
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
}

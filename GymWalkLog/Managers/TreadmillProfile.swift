import CoreGraphics
import Foundation

// 各指標（距離・時間・カロリー）のどの画像領域に表示されているかを記憶する
struct RegionMemory: Codable {
    var box: CGRect     // Vision座標系（正規化 0-1、左下原点）
    var hitCount: Int   // 何回この領域で正しく読み取れたか
}

struct TreadmillProfile: Codable {
    var distanceRegion: RegionMemory?
    var durationRegion: RegionMemory?
    var caloriesRegion: RegionMemory?

    var hasLearned: Bool {
        distanceRegion != nil || durationRegion != nil || caloriesRegion != nil
    }

    var minHitCount: Int {
        [distanceRegion, durationRegion, caloriesRegion]
            .compactMap { $0?.hitCount }.min() ?? 0
    }

    // MARK: - 永続化

    private static let key = "treadmill_profile_v1"

    static func load() -> TreadmillProfile {
        guard let data = UserDefaults.standard.data(forKey: key),
              let p = try? JSONDecoder().decode(TreadmillProfile.self, from: data)
        else { return TreadmillProfile() }
        return p
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    // MARK: - 学習（指数移動平均で位置を補正）

    mutating func learn(distanceBox: CGRect?, durationBox: CGRect?, caloriesBox: CGRect?) {
        if let b = distanceBox { distanceRegion = smooth(distanceRegion, toward: b) }
        if let b = durationBox  { durationRegion  = smooth(durationRegion,  toward: b) }
        if let b = caloriesBox  { caloriesRegion  = smooth(caloriesRegion,  toward: b) }
    }

    private func smooth(_ existing: RegionMemory?, toward box: CGRect) -> RegionMemory {
        guard let e = existing else { return RegionMemory(box: box, hitCount: 1) }
        let t: CGFloat = 0.2   // 学習率（小さいほど変化が緩やか）
        let smoothed = CGRect(
            x: e.box.minX + (box.minX - e.box.minX) * t,
            y: e.box.minY + (box.minY - e.box.minY) * t,
            width: e.box.width  + (box.width  - e.box.width)  * t,
            height: e.box.height + (box.height - e.box.height) * t
        )
        return RegionMemory(box: smoothed, hitCount: e.hitCount + 1)
    }

    // MARK: - 領域判定（±20% の余白を持たせて判定）

    enum MetricType { case distance, duration, calories }

    func isInKnownRegion(_ box: CGRect, for type: MetricType) -> Bool {
        let region: RegionMemory?
        switch type {
        case .distance: region = distanceRegion
        case .duration: region = durationRegion
        case .calories: region = caloriesRegion
        }
        guard let r = region else { return false }
        let expanded = r.box.insetBy(dx: -0.12, dy: -0.10)
        return expanded.intersects(box)
    }
}

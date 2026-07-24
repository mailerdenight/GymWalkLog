import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let outputDir = root.appendingPathComponent("screenshots/iap-review", isDirectory: true)
let outputURL = outputDir.appendingPathComponent("pro-review-screenshot-ipad.png")
let logoURL = root.appendingPathComponent("GymWalkLog/Assets.xcassets/AppLogo.imageset/AppLogo.png")

try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

let canvas = CGSize(width: 2064, height: 2752)
let backgroundTop = NSColor(calibratedRed: 0.99, green: 0.97, blue: 0.90, alpha: 1.0)
let backgroundBottom = NSColor(calibratedRed: 0.93, green: 0.98, blue: 0.95, alpha: 1.0)
let accent = NSColor(calibratedRed: 0.29, green: 0.57, blue: 0.37, alpha: 1.0)
let accentSoft = accent.withAlphaComponent(0.12)
let cardColor = NSColor.white
let textPrimary = NSColor(calibratedRed: 0.11, green: 0.15, blue: 0.12, alpha: 1.0)
let textSecondary = NSColor(calibratedRed: 0.31, green: 0.38, blue: 0.34, alpha: 1.0)

func drawGradient(in rect: CGRect, top: NSColor, bottom: NSColor) {
    guard let context = NSGraphicsContext.current?.cgContext,
          let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [top.cgColor, bottom.cgColor] as CFArray,
            locations: [0, 1]
          ) else { return }

    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: rect.midX, y: rect.maxY),
        end: CGPoint(x: rect.midX, y: rect.minY),
        options: []
    )
}

func drawRoundedRect(_ rect: CGRect, radius: CGFloat, fill: NSColor) {
    fill.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}

func drawText(
    _ string: String,
    in rect: CGRect,
    size: CGFloat,
    weight: NSFont.Weight,
    color: NSColor,
    alignment: NSTextAlignment = .left,
    lineHeight: CGFloat? = nil
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    if let lineHeight {
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
    }

    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color,
        .paragraphStyle: paragraph
    ]

    NSString(string: string).draw(in: rect, withAttributes: attributes)
}

func drawCheckRow(y: CGFloat, title: String, body: String) {
    let iconRect = CGRect(x: 280, y: y + 32, width: 52, height: 52)
    drawRoundedRect(iconRect, radius: 26, fill: accent)
    drawText("✓", in: iconRect.offsetBy(dx: 0, dy: 4), size: 28, weight: .bold, color: .white, alignment: .center)
    drawText(title, in: CGRect(x: 360, y: y + 36, width: 1220, height: 42), size: 34, weight: .semibold, color: textPrimary)
    drawText(body, in: CGRect(x: 360, y: y - 12, width: 1220, height: 58), size: 24, weight: .regular, color: textSecondary, lineHeight: 34)
}

let image = NSImage(size: canvas)
image.lockFocus()

let bounds = CGRect(origin: .zero, size: canvas)
drawGradient(in: bounds, top: backgroundTop, bottom: backgroundBottom)

drawRoundedRect(CGRect(x: -120, y: 2240, width: 520, height: 520), radius: 260, fill: accentSoft)
drawRoundedRect(CGRect(x: 1680, y: 2100, width: 420, height: 420), radius: 210, fill: accentSoft)
drawRoundedRect(CGRect(x: 1520, y: 140, width: 580, height: 580), radius: 290, fill: NSColor.white.withAlphaComponent(0.30))

let cardRect = CGRect(x: 180, y: 220, width: 1704, height: 2260)
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.10)
shadow.shadowBlurRadius = 36
shadow.shadowOffset = CGSize(width: 0, height: -12)

NSGraphicsContext.saveGraphicsState()
shadow.set()
drawRoundedRect(cardRect, radius: 56, fill: cardColor)
NSGraphicsContext.restoreGraphicsState()

drawRoundedRect(CGRect(x: cardRect.minX, y: cardRect.maxY - 220, width: cardRect.width, height: 220), radius: 56, fill: accent)
drawRoundedRect(CGRect(x: cardRect.minX, y: cardRect.maxY - 240, width: cardRect.width, height: 60), radius: 0, fill: accent)

if let logo = NSImage(contentsOf: logoURL) {
    logo.draw(in: CGRect(x: 290, y: 2120, width: 132, height: 132))
}

drawText("ジム歩走ログ Pro", in: CGRect(x: 450, y: 2168, width: 980, height: 72), size: 58, weight: .bold, color: .white)
drawText("買い切りアップグレード", in: CGRect(x: 450, y: 2116, width: 800, height: 48), size: 30, weight: .medium, color: .white.withAlphaComponent(0.92))

drawText(
    "31件目以降の記録、詳細グラフ、\n写真無制限、PDF/CSV出力、iCloud同期を解放",
    in: CGRect(x: 250, y: 1830, width: 1560, height: 170),
    size: 54,
    weight: .heavy,
    color: textPrimary,
    alignment: .center,
    lineHeight: 70
)

drawText(
    "This screenshot is for App Review and shows the non-consumable Pro upgrade offered in the app.",
    in: CGRect(x: 260, y: 1754, width: 1540, height: 44),
    size: 23,
    weight: .medium,
    color: textSecondary,
    alignment: .center
)

drawCheckRow(y: 1460, title: "31件目以降の記録を保存", body: "無料版30件を超えたあとも、運動ログを継続して保存できます。")
drawCheckRow(y: 1280, title: "週・月・年のレポートを確認", body: "歩行距離、時間、カロリーの推移をグラフで振り返れます。")
drawCheckRow(y: 1100, title: "写真を無制限に添付", body: "トレッドミル画面の写真を件数制限なく保存できます。")
drawCheckRow(y: 920, title: "PDF / CSVでエクスポート", body: "自分の記録を外部に書き出して保管できます。")
drawCheckRow(y: 740, title: "iCloudで自動同期", body: "同じApple IDの端末間で記録を同期できます。")

drawRoundedRect(CGRect(x: 290, y: 420, width: 1484, height: 120), radius: 30, fill: accent)
drawText(
    "Proにする（買い切り）",
    in: CGRect(x: 290, y: 452, width: 1484, height: 50),
    size: 40,
    weight: .bold,
    color: .white,
    alignment: .center
)

drawText(
    "Product ID: com.gymwalklog.app.pro",
    in: CGRect(x: 290, y: 356, width: 1484, height: 36),
    size: 24,
    weight: .medium,
    color: textSecondary,
    alignment: .center
)
drawText(
    "サブスクリプションなし / Non-Consumable",
    in: CGRect(x: 290, y: 316, width: 1484, height: 36),
    size: 24,
    weight: .medium,
    color: textSecondary,
    alignment: .center
)

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    throw NSError(domain: "IAPReviewScreenshot", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode PNG"])
}

try png.write(to: outputURL)
print("Wrote \(outputURL.path)")

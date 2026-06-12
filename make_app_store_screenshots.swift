import AppKit
import CoreGraphics
import Foundation

struct ShotSpec {
    let source: String
    let output: String
    let title: String
    let subtitle: String
    let top: NSColor
    let bottom: NSColor
    let accent: NSColor
    let text: NSColor
    let cardY: CGFloat
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let inputDir = root.appendingPathComponent("screenshots/appstore")
let outputDir = root.appendingPathComponent("screenshots/appstore-polished")
try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

let specs: [ShotSpec] = [
    ShotSpec(
        source: "01-onboarding.png",
        output: "01-start.png",
        title: "ジムの歩き・走りを\nやさしく記録",
        subtitle: "トレッドミル専用のシンプルな運動ログ",
        top: NSColor(calibratedRed: 1.00, green: 0.86, blue: 0.32, alpha: 1),
        bottom: NSColor(calibratedRed: 1.00, green: 0.98, blue: 0.88, alpha: 1),
        accent: NSColor(calibratedRed: 0.14, green: 0.13, blue: 0.10, alpha: 1),
        text: NSColor(calibratedRed: 0.12, green: 0.11, blue: 0.09, alpha: 1),
        cardY: 690
    ),
    ShotSpec(
        source: "02-home.png",
        output: "02-month.png",
        title: "今月のがんばりが\nひと目でわかる",
        subtitle: "回数・距離・カロリーを自動で集計",
        top: NSColor(calibratedRed: 0.81, green: 0.93, blue: 0.85, alpha: 1),
        bottom: NSColor(calibratedRed: 0.95, green: 0.99, blue: 0.96, alpha: 1),
        accent: NSColor(calibratedRed: 0.25, green: 0.49, blue: 0.33, alpha: 1),
        text: NSColor(calibratedRed: 0.09, green: 0.17, blue: 0.12, alpha: 1),
        cardY: 640
    ),
    ShotSpec(
        source: "03-stats.png",
        output: "03-stats.png",
        title: "Proでくわしく\nグラフ分析",
        subtitle: "購入後は週・月・年の統計をすぐ確認",
        top: NSColor(calibratedRed: 0.83, green: 0.90, blue: 1.00, alpha: 1),
        bottom: NSColor(calibratedRed: 0.96, green: 0.98, blue: 1.00, alpha: 1),
        accent: NSColor(calibratedRed: 0.18, green: 0.33, blue: 0.68, alpha: 1),
        text: NSColor(calibratedRed: 0.08, green: 0.13, blue: 0.25, alpha: 1),
        cardY: 690
    ),
    ShotSpec(
        source: "04-records.png",
        output: "04-list.png",
        title: "写真つきで\n記録を見返せる",
        subtitle: "距離・時間・カロリー・ペースを一覧化",
        top: NSColor(calibratedRed: 1.00, green: 0.88, blue: 0.76, alpha: 1),
        bottom: NSColor(calibratedRed: 1.00, green: 0.97, blue: 0.93, alpha: 1),
        accent: NSColor(calibratedRed: 0.82, green: 0.34, blue: 0.18, alpha: 1),
        text: NSColor(calibratedRed: 0.24, green: 0.12, blue: 0.07, alpha: 1),
        cardY: 650
    ),
    ShotSpec(
        source: "05-calendar.png",
        output: "05-calendar.png",
        title: "通った日が\nカレンダーに残る",
        subtitle: "月間目標と達成状況で習慣化をサポート",
        top: NSColor(calibratedRed: 0.90, green: 0.84, blue: 1.00, alpha: 1),
        bottom: NSColor(calibratedRed: 0.98, green: 0.96, blue: 1.00, alpha: 1),
        accent: NSColor(calibratedRed: 0.42, green: 0.25, blue: 0.67, alpha: 1),
        text: NSColor(calibratedRed: 0.17, green: 0.10, blue: 0.28, alpha: 1),
        cardY: 650
    ),
    ShotSpec(
        source: "06-album.png",
        output: "06-album.png",
        title: "トレッドミル画面も\nまとめて保存",
        subtitle: "写真からあとで数値を確認しやすい",
        top: NSColor(calibratedRed: 0.78, green: 0.96, blue: 0.95, alpha: 1),
        bottom: NSColor(calibratedRed: 0.94, green: 1.00, blue: 0.99, alpha: 1),
        accent: NSColor(calibratedRed: 0.00, green: 0.47, blue: 0.48, alpha: 1),
        text: NSColor(calibratedRed: 0.03, green: 0.20, blue: 0.20, alpha: 1),
        cardY: 650
    )
]

let canvasSize = CGSize(width: 1320, height: 2868)
let phoneWidth: CGFloat = 930
let cropTop: CGFloat = 190

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

func drawRoundedRect(_ rect: CGRect, radius: CGFloat, color: NSColor) {
    color.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}

func drawText(_ string: String, in rect: CGRect, fontSize: CGFloat, weight: NSFont.Weight, color: NSColor, alignment: NSTextAlignment, lineHeight: CGFloat? = nil) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    if let lineHeight {
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
    }
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: fontSize, weight: weight),
        .foregroundColor: color,
        .paragraphStyle: paragraph
    ]
    NSString(string: string).draw(in: rect, withAttributes: attrs)
}

func drawPhone(from image: NSImage, in rect: CGRect) {
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
    let cropHeight = CGFloat(cgImage.height) - cropTop
    guard let cropped = cgImage.cropping(to: CGRect(x: 0, y: cropTop, width: CGFloat(cgImage.width), height: cropHeight)) else { return }

    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.20)
    shadow.shadowBlurRadius = 38
    shadow.shadowOffset = CGSize(width: 0, height: -20)

    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    drawRoundedRect(rect.insetBy(dx: -8, dy: -8), radius: 64, color: .white)
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: rect, xRadius: 56, yRadius: 56).addClip()
    NSImage(cgImage: cropped, size: rect.size).draw(in: rect)
    NSGraphicsContext.restoreGraphicsState()
}

func render(_ spec: ShotSpec) throws {
    guard let sourceImage = NSImage(contentsOf: inputDir.appendingPathComponent(spec.source)) else {
        throw NSError(domain: "Screenshots", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing \(spec.source)"])
    }

    let output = NSImage(size: canvasSize)
    output.lockFocus()
    let bounds = CGRect(origin: .zero, size: canvasSize)
    drawGradient(in: bounds, top: spec.top, bottom: spec.bottom)

    drawRoundedRect(CGRect(x: -130, y: 2280, width: 460, height: 460), radius: 230, color: spec.accent.withAlphaComponent(0.12))
    drawRoundedRect(CGRect(x: 1010, y: 2120, width: 430, height: 430), radius: 215, color: spec.accent.withAlphaComponent(0.10))
    drawRoundedRect(CGRect(x: 920, y: 260, width: 620, height: 620), radius: 310, color: .white.withAlphaComponent(0.34))

    drawText(
        spec.title,
        in: CGRect(x: 96, y: 2258, width: 1128, height: 270),
        fontSize: 76,
        weight: .heavy,
        color: spec.text,
        alignment: .center,
        lineHeight: 88
    )

    drawText(
        spec.subtitle,
        in: CGRect(x: 116, y: 2140, width: 1088, height: 74),
        fontSize: 34,
        weight: .semibold,
        color: spec.text.withAlphaComponent(0.72),
        alignment: .center,
        lineHeight: 44
    )

    let phoneHeight = phoneWidth * (2868 - cropTop) / 1320
    let phoneRect = CGRect(x: (canvasSize.width - phoneWidth) / 2, y: 170, width: phoneWidth, height: phoneHeight)
    drawPhone(from: sourceImage, in: phoneRect)

    drawRoundedRect(CGRect(x: 108, y: 126, width: 1104, height: 96), radius: 48, color: spec.accent)
    drawText(
        "ジム歩走ログ",
        in: CGRect(x: 108, y: 146, width: 1104, height: 52),
        fontSize: 32,
        weight: .bold,
        color: .white,
        alignment: .center
    )

    output.unlockFocus()

    guard let tiff = output.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "Screenshots", code: 2, userInfo: [NSLocalizedDescriptionKey: "PNG conversion failed"])
    }
    try png.write(to: outputDir.appendingPathComponent(spec.output))
}

for spec in specs {
    try render(spec)
}

print("Wrote \(specs.count) polished screenshots to \(outputDir.path)")

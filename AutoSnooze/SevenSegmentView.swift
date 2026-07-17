import SwiftUI

/// Shared LED display colors.
enum LED {
    /// Lit segment — classic red-orange LED.
    static let on = Color(red: 1.0, green: 0.165, blue: 0.0)
    /// Unlit "ghost" segment, faintly visible like a real LED panel.
    static let off = Color(red: 0.16, green: 0.026, blue: 0.0)
}

/// One digit of a 7-segment LED display, drawn in a 1 x 2 unit space.
///
///      ┌─ a ─┐
///      f     b
///      ├─ g ─┤
///      e     c
///      └─ d ─┘
struct SevenSegmentDigit: View {
    /// "0"..."9", or " " for a blank position (all segments ghosted).
    var character: Character

    private static let thickness: CGFloat = 0.20
    private static let gap: CGFloat = 0.025

    private static let litSegments: [Character: Set<Character>] = [
        "0": ["a", "b", "c", "d", "e", "f"],
        "1": ["b", "c"],
        "2": ["a", "b", "g", "e", "d"],
        "3": ["a", "b", "g", "c", "d"],
        "4": ["f", "g", "b", "c"],
        "5": ["a", "f", "g", "c", "d"],
        "6": ["a", "f", "g", "e", "c", "d"],
        "7": ["a", "b", "c"],
        "8": ["a", "b", "c", "d", "e", "f", "g"],
        "9": ["a", "b", "c", "d", "f", "g"],
        " ": [],
    ]

    /// Hexagonal segment outlines in the unit space, computed once.
    private static let segmentPolygons: [Character: [CGPoint]] = {
        let ht = thickness / 2

        func horizontal(_ x0: CGFloat, _ x1: CGFloat, _ yc: CGFloat) -> [CGPoint] {
            let x0 = x0 + gap, x1 = x1 - gap
            return [
                CGPoint(x: x0, y: yc),
                CGPoint(x: x0 + ht, y: yc - ht),
                CGPoint(x: x1 - ht, y: yc - ht),
                CGPoint(x: x1, y: yc),
                CGPoint(x: x1 - ht, y: yc + ht),
                CGPoint(x: x0 + ht, y: yc + ht),
            ]
        }

        func vertical(_ y0: CGFloat, _ y1: CGFloat, _ xc: CGFloat) -> [CGPoint] {
            let y0 = y0 + gap, y1 = y1 - gap
            return [
                CGPoint(x: xc, y: y0),
                CGPoint(x: xc + ht, y: y0 + ht),
                CGPoint(x: xc + ht, y: y1 - ht),
                CGPoint(x: xc, y: y1),
                CGPoint(x: xc - ht, y: y1 - ht),
                CGPoint(x: xc - ht, y: y0 + ht),
            ]
        }

        return [
            "a": horizontal(0, 1, ht),
            "g": horizontal(0, 1, 1),
            "d": horizontal(0, 1, 2 - ht),
            "f": vertical(0, 1, ht),
            "b": vertical(0, 1, 1 - ht),
            "e": vertical(1, 2, ht),
            "c": vertical(1, 2, 1 - ht),
        ]
    }()

    var body: some View {
        Canvas { context, size in
            let u = min(size.width, size.height / 2)
            let lit = Self.litSegments[character] ?? []
            for (segment, polygon) in Self.segmentPolygons {
                var path = Path()
                path.addLines(polygon.map { CGPoint(x: $0.x * u, y: $0.y * u) })
                path.closeSubpath()
                context.fill(path, with: .color(lit.contains(segment) ? LED.on : LED.off))
            }
        }
        .aspectRatio(0.5, contentMode: .fit)
    }
}

/// The ":" between hours and minutes — two square LED dots, steady (no blink).
struct SegmentColon: View {
    var body: some View {
        Canvas { context, size in
            let u = min(size.width / 0.45, size.height / 2)
            let dot = 0.22 * u
            let x = (size.width - dot) / 2
            for yc in [0.55 * u, 1.3 * u] {
                context.fill(Path(CGRect(x: x, y: yc, width: dot, height: dot)),
                             with: .color(LED.on))
            }
        }
        .aspectRatio(0.225, contentMode: .fit)
    }
}

/// The full clock face: HH:MM digits, AM/PM in 12-hour mode, and one
/// indicator dot per alarm. Scales to fill the available space so rotation
/// just reflows.
struct ClockFaceView: View {
    var hour: Int
    var minute: Int
    var alarmsEnabled: [Bool]

    private var is12Hour: Bool {
        let cycle = Locale.current.hourCycle
        return cycle == .oneToTwelve || cycle == .zeroToEleven
    }

    private var digits: [Character] {
        let displayHour = is12Hour ? (hour % 12 == 0 ? 12 : hour % 12) : hour
        let h = String(format: "%02d", displayHour)
        let m = String(format: "%02d", minute)
        let hourTens: Character = (is12Hour && displayHour < 10) ? " " : h.first!
        return [hourTens, h.last!, m.first!, m.last!]
    }

    var body: some View {
        GeometryReader { geo in
            // Width in digit-units: 4 digits + colon (0.45) + 4 gaps (0.22).
            // Height: 2 for digits + 0.55 for the indicator row.
            let u = min(geo.size.width / 5.33, geo.size.height / 2.55)
            let spacing = 0.22 * u
            let digits = digits

            VStack(spacing: 0.15 * u) {
                HStack(alignment: .center, spacing: spacing) {
                    ForEach(0..<4, id: \.self) { i in
                        SevenSegmentDigit(character: digits[i])
                            .frame(width: u, height: 2 * u)
                        if i == 1 {
                            SegmentColon()
                                .frame(width: 0.45 * u, height: 2 * u)
                        }
                    }
                }
                HStack(spacing: 0.35 * u) {
                    if is12Hour {
                        Text(hour < 12 ? "AM" : "PM")
                            .foregroundStyle(LED.on)
                    }
                    ForEach(alarmsEnabled.indices, id: \.self) { i in
                        Label("AL\(i + 1)", systemImage: "circle.fill")
                            .foregroundStyle(alarmsEnabled[i] ? LED.on : LED.off)
                    }
                }
                .font(.system(size: 0.24 * u, weight: .bold, design: .rounded))
                .imageScale(.small)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ClockFaceView(hour: 21, minute: 47, alarmsEnabled: [true, false])
            .padding(24)
    }
}

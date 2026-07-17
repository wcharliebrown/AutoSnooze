import Foundation
import Observation

struct Alarm: Codable, Equatable {
    var enabled: Bool
    var hour: Int
    var minute: Int
    var soundName: String
}

/// Holds the two alarms, persists them, and fires each one exactly once when
/// its minute arrives. Alarms only sound while the app is in the foreground —
/// this is a bedside clock that stays open all night.
@Observable
final class AlarmStore {
    static let soundNames = ["chime", "gong", "bell", "beep"]
    private static let defaultsKey = "alarms"

    var alarms: [Alarm] {
        didSet {
            save()
            // Editing an alarm to the current minute shouldn't blast the
            // sound immediately — treat this minute as already handled.
            let key = Self.minuteKey(for: Date())
            for i in alarms.indices { lastFired[i] = key }
        }
    }

    /// Minute key each alarm last fired for, so an alarm sounds once per
    /// matching minute and naturally survives clock/DST changes.
    private var lastFired: [Int: String] = [:]
    @ObservationIgnored private var timer: Timer?

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
           let saved = try? JSONDecoder().decode([Alarm].self, from: data),
           saved.count == 2 {
            alarms = saved
        } else {
            alarms = [
                Alarm(enabled: false, hour: 7, minute: 0, soundName: "chime"),
                Alarm(enabled: false, hour: 8, minute: 0, soundName: "gong"),
            ]
        }
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        timer.tolerance = 0.2
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func tick(now: Date = Date()) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: now)
        let key = Self.minuteKey(for: now)
        for i in alarms.indices {
            let alarm = alarms[i]
            guard alarm.enabled,
                  alarm.hour == components.hour,
                  alarm.minute == components.minute,
                  lastFired[i] != key
            else { continue }
            lastFired[i] = key
            AlarmSoundPlayer.shared.play(alarm.soundName)
        }
    }

    private static func minuteKey(for date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return "\(c.year!)-\(c.month!)-\(c.day!) \(c.hour!):\(c.minute!)"
    }

    private func save() {
        if let data = try? JSONEncoder().encode(alarms) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }
}

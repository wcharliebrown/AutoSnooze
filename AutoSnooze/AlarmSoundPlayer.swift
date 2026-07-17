import AVFoundation

/// Plays a bundled alarm sound exactly once. Uses the `.playback` audio
/// session category so the alarm sounds even when the silent switch is on.
final class AlarmSoundPlayer: NSObject, AVAudioPlayerDelegate {
    static let shared = AlarmSoundPlayer()

    private var player: AVAudioPlayer?

    func play(_ soundName: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "wav") else {
            return
        }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback)
        try? session.setActive(true)

        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.delegate = self
        player.numberOfLoops = 0
        self.player = player
        player.play()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.player = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

import AVFoundation
import MediaPlayer

class AudioSessionManager {
    static let shared = AudioSessionManager()
    
    private init() {}

    /// Setzt die Audio-Session für `AVPlayer` (Radio/Podcast)
    func activateAVPlayerSession() {
        deactivateAudioSession() // ✅ Zuerst vorherige Session deaktivieren
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth])
            try AVAudioSession.sharedInstance().setActive(true)
            print("🎵 Audio-Session aktiviert für AVPlayer (Radio/Podcast)")
        } catch {
            print("❌ Fehler beim Aktivieren der AVPlayer-Session: \(error.localizedDescription)")
        }
    }

    /// Setzt die Audio-Session für `MPMusicPlayerController` (Apple Music)
    func activateMusicPlayerSession() {
        deactivateAudioSession() // ✅ Vorherige Session deaktivieren
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.allowAirPlay, .allowBluetooth])
            try AVAudioSession.sharedInstance().setActive(true)
            print("🎵 Audio-Session aktiviert für Apple Music")
        } catch {
            print("❌ Fehler beim Aktivieren der MusicPlayer-Session: \(error.localizedDescription)")
        }
    }

    /// Deaktiviert die aktuelle Audio-Session
    func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            print("🔇 Audio-Session deaktiviert")
        } catch {
            print("❌ Fehler beim Deaktivieren der Audio-Session: \(error.localizedDescription)")
        }
    }
}

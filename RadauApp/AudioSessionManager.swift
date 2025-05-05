import AVFoundation
import MediaPlayer

class AudioSessionManager {
    static let shared = AudioSessionManager()
    private var isAudioSessionActive = false // 🚀 Neuer Status

    private init() {}

    /// Setzt die Audio-Session für `AVPlayer` (Radio/Podcast)
    func activateAVPlayerSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // 🛠 Falls die Session bereits aktiv ist, erst deaktivieren
            if audioSession.isOtherAudioPlaying {
                print("🔇 Deaktiviere andere Audio-Sessions zuerst...")
                try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            }
            
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true, options: [])
            
            print("🎵 Audio-Session erfolgreich für AVPlayer aktiviert!")
        } catch let error as NSError {
            print("❌ Fehler beim Aktivieren der AVPlayer-Session: \(error.localizedDescription), Code: \(error.code)")
        }
    }

    /// Setzt die Audio-Session für `MPMusicPlayerController` (Apple Music)
    func activateMusicPlayerSession() {
        if isAudioSessionActive { return } // ✅ Verhindert unnötige Aktivierungen
        deactivateAudioSession()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth])
                try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                self.isAudioSessionActive = true
                print("🎵 Audio-Session aktiviert für Apple Music")
            } catch let error as NSError {
                print("❌ Fehler beim Aktivieren der MusicPlayer-Session: \(error.localizedDescription), Code: \(error.code)")
            }
        }
    }

    /// Deaktiviert die aktuelle Audio-Session
    func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            print("🔇 Audio-Session erfolgreich deaktiviert!")
        } catch let error as NSError {
            print("❌ Fehler beim Deaktivieren der Audio-Session: \(error.localizedDescription), Code: \(error.code)")
        }
    }
}

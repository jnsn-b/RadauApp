import Foundation
import AVFoundation

/// Struktur zur Repräsentation eines Songs oder eines Radio-Streams
struct Song {
    var title: String
    var artist: String
}

/// `AVPlayer`-basierter Audio-Player für Podcasts & Radio
class AVPlayerAudioPlayer: ObservableObject, AudioPlayerProtocol {
    private var player: AVPlayer?
    
    // `currentSong`-Eigenschaft, um den Radio-Sendernamen zu speichern
    @Published var currentSong: Song?

    // Der Initializer muss die URL akzeptieren
    init(url: URL, stationName: String?) {
        self.player = AVPlayer(url: url)  // `avPlayer` zu `player` geändert
        
        // Setze den aktuellen Song mit dem Sendernamen (falls angegeben)
        self.currentSong = Song(title: stationName ?? "Unbekannter Sender", artist: "Radio")
    }

    func play() {
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    func stop() {
        player?.pause()
        player?.seek(to: .zero)
    }

    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 1)
        player?.seek(to: cmTime)
    }

    var isPlaying: Bool {
        player?.timeControlStatus == .playing
    }

    /// Setzt die aktuelle Audio-URL für Podcasts oder Radio
    func loadURL(_ url: URL) {
        let playerItem = AVPlayerItem(url: url)
        player?.replaceCurrentItem(with: playerItem)
    }
    
    func shuffle() {
        // Optional: Shuffle logic for Podcasts or Radio, if needed
    }
}

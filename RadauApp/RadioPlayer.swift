import AVFoundation
import SwiftUI

class RadioPlayer: ObservableObject {
    static let shared = RadioPlayer()
    private var player: AVPlayer?
    @Published var isPlaying: Bool = false
    @Published var currentRadio: Radio?

   

    /// Startet das Radio-Streaming
    func play(radio: Radio) {
        AudioSessionManager.shared.activateAVPlayerSession()
        var streamURL = radio.streamURL

        // Falls HTTP-Stream existiert, versuche HTTPS, falls ATS es erlaubt
        if streamURL.hasPrefix("http://") {
            let secureURL = streamURL.replacingOccurrences(of: "http://", with: "https://")
            if canPlayURL(secureURL) {
                streamURL = secureURL
            }
        }

        guard let url = URL(string: streamURL) else {
            print("❌ Ungültige Stream-URL: \(streamURL)")
            return
        }

        print("▶️ Versuche Stream zu starten: \(streamURL)")

        // AVPlayer initialisieren und abspielen
        self.currentRadio = radio
        self.player = AVPlayer(url: url)
        self.player?.play()
        self.isPlaying = true

        print("✅ Playback gestartet für \(radio.name)")
    }

    /// Stoppt die Wiedergabe
    func stop() {
        self.player?.pause()
        self.isPlaying = false
        print("⏹️ Wiedergabe gestoppt")
    }

    /// Prüft, ob eine URL abgespielt werden kann
    private func canPlayURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        let semaphore = DispatchSemaphore(value: 0)
        var isPlayable = false

        URLSession.shared.dataTask(with: request) { _, response, _ in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                isPlayable = true
            }
            semaphore.signal()
        }.resume()

        semaphore.wait()
        return isPlayable
    }
}

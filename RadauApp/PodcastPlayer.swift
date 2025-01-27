import Foundation
import AVFoundation
import FeedKit

class PodcastPlayer: ObservableObject {
    @Published var currentEpisode: PodcastFetcher.PodcastEpisode? // Verwende den Typ aus PodcastFetcher
    var player: AVPlayer?

    init() {
        // Setze die Audio-Sitzung, um die Hintergrundwiedergabe zu ermöglichen
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Fehler beim Konfigurieren der AVAudioSession: \(error)")
        }
    }

    // Funktion, um eine Episode abzuspielen
    func play(episode: PodcastFetcher.PodcastEpisode) {
        self.currentEpisode = episode
        print("Spiele Episode: \(episode.title), URL: \(episode.playbackURL)") // Debug-Ausgabe

        // Falls eine gültige URL für die Episode vorhanden ist
        if let url = URL(string: episode.playbackURL) {
            print("Gültige URL: \(url)")
            
            // Lade und spiele direkt ab
            playStream(url: url)
        } else {
            print("Keine gültige URL für die Episode.")
        }
    }

    private func playStream(url: URL) {
        // Erstelle ein AVAsset direkt aus der URL
        let asset = AVAsset(url: url)
        
        // Erstelle einen AVPlayerItem aus dem Asset
        let playerItem = AVPlayerItem(asset: asset)
        
        // AVPlayer initialisieren
        self.player = AVPlayer(playerItem: playerItem)
        
        // Starte die Wiedergabe
        self.player?.play()
        print("AVPlayer gestartet mit Stream URL: \(url)")
    }

    // Funktion, um zur nächsten Episode zu wechseln (falls vorhanden)
    func next(episodes: [PodcastFetcher.PodcastEpisode], currentEpisode: PodcastFetcher.PodcastEpisode) {
        if let currentIndex = episodes.firstIndex(where: { $0.id == currentEpisode.id }) {
            let nextIndex = currentIndex + 1
            if nextIndex < episodes.count {
                let nextEpisode = episodes[nextIndex]
                play(episode: nextEpisode)
            }
        }
    }

    // Funktion, um zur vorherigen Episode zu wechseln (falls vorhanden)
    func previous(episodes: [PodcastFetcher.PodcastEpisode], currentEpisode: PodcastFetcher.PodcastEpisode) {
        if let currentIndex = episodes.firstIndex(where: { $0.id == currentEpisode.id }) {
            let previousIndex = currentIndex - 1
            if previousIndex >= 0 {
                let previousEpisode = episodes[previousIndex]
                play(episode: previousEpisode)
            }
        }
    }

    // Funktion, um das Abspielen zu stoppen
    func stop() {
        player?.pause()
        player = nil
    }

    // Funktion, um das aktuelle Abspielen der Episode zu überspringen
    func skipForward(seconds: TimeInterval) {
        if let currentTime = player?.currentTime() {
            let newTime = currentTime + CMTime(seconds: seconds, preferredTimescale: 1)
            player?.seek(to: newTime)
        }
    }

    // Funktion, um das Abspielen zurückzuspulen
    func skipBackward(seconds: TimeInterval) {
        if let currentTime = player?.currentTime() {
            let newTime = currentTime - CMTime(seconds: seconds, preferredTimescale: 1)
            player?.seek(to: newTime)
        }
    }
    
    
}

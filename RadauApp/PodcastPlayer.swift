import Foundation
import AVFoundation
import FeedKit

class PodcastPlayer: ObservableObject {
    @Published var currentEpisode: PodcastFetcher.PodcastEpisode? // Verwende den Typ aus PodcastFetcher
    var player: AVPlayer?

   
func play(episode: PodcastFetcher.PodcastEpisode) {
                // Falls bereits eine Episode läuft, stoppe sie zuerst
                if let currentEpisode = currentEpisode {
                    print("🛑 Stoppe vorherige Episode: \(currentEpisode.title)")
                    stop()
                }

                // Setze die aktuelle Episode
                self.currentEpisode = episode
                print("▶️ Spiele Episode: \(episode.title), URL: \(episode.playbackURL)")

                // Stelle sicher, dass die Audio-Session aktiv ist
                AudioSessionManager.shared.activateAVPlayerSession()

                // Überprüfe, ob die URL gültig ist
                guard let url = URL(string: episode.playbackURL) else {
                    print("❌ Ungültige URL für die Episode: \(episode.title)")
                    return
                }

                print("🔗 Lade Stream von: \(url)")

                // AVPlayer initialisieren und starten
                let playerItem = AVPlayerItem(url: url)
                self.player = AVPlayer(playerItem: playerItem)

                // Beginne mit der Wiedergabe
                self.player?.play()
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

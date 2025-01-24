import Foundation
import AVFoundation
import FeedKit

// Der PodcastPlayer, der zum Abspielen der Episoden zuständig ist
class PodcastPlayer: ObservableObject {  // <- Hinzufügen von ObservableObject
    @Published var currentEpisode: PodcastFetcher.PodcastEpisode? // Verwende den Typ aus PodcastFetcher
    var player: AVPlayer?

    // Funktion, um eine Episode abzuspielen
    func play(episode: PodcastFetcher.PodcastEpisode) {
        self.currentEpisode = episode

        // Falls eine gültige URL für die Episode vorhanden ist
        if let url = URL(string: episode.playbackURL) {
            player = AVPlayer(url: url)
            player?.play()
        } else {
            print("Keine gültige URL für die Episode.")
        }
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

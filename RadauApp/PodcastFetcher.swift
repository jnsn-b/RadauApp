import Foundation
import FeedKit
import UIKit



class PodcastFetcher: ObservableObject {
    
    @Published var podcasts: [Podcast] = []

    // Modell für einen abonnierten Podcast
    struct Podcast: Identifiable {
        var id: String
        var name: String
        var artworkData: Data? // Optional: Speichern von Bilddaten als Data (z.B. Base64)
        var rssFeedURL: String // URL des RSS-Feeds
        var episodes: [PodcastEpisode] = []
    }

    // Modell für eine Episode eines Podcasts
    struct PodcastEpisode: Identifiable {
        var id: String
        var title: String
        var podcastName: String
        var playbackDurationString: String
        var playbackURL: String
    }

    static func loadPodcastArtwork(for podcast: Podcast, completion: @escaping (UIImage?) -> Void) {
        // Falls keine Artwork-Daten vorhanden sind, gebe nil zurück
        guard let artworkData = podcast.artworkData else {
            completion(nil)
            return
        }

        // Wenn die Artwork-Daten bereits vorhanden sind, sofort in UIImage umwandeln
        if let image = UIImage(data: artworkData) {
            completion(image)
        } else {
            // Rückgabe von nil, falls die Umwandlung fehlschlägt
            completion(nil)
        }
    }
    
    static func fetchEpisodes(from rssFeedURL: String, podcast: Podcast, completion: @escaping (Podcast, [PodcastEpisode]) -> Void) {
        guard let url = URL(string: rssFeedURL) else {
            print("Ungültige RSS-URL")
            return
        }
        
        let parser = FeedParser(URL: url)
        parser.parseAsync { result in
            switch result {
            case .success(let feed):
                var episodes: [PodcastEpisode] = []
                var podcastTitle: String = podcast.name  // Verwende den Namen des übergebenen Podcasts
                
                switch feed {
                case .rss(let rssFeed):
                    podcastTitle = rssFeed.title ?? podcast.name // Falls kein Titel vorhanden ist, benutze den übergebenen Namen
                    
                    if let items = rssFeed.items {
                        for item in items {
                            let duration = parseTimeInterval(item.iTunes?.iTunesDuration)
                            let durationString = String(duration)
                            let episode = PodcastEpisode(
                                id: item.guid?.value ?? UUID().uuidString,
                                title: item.title ?? "Unbenannte Episode",
                                podcastName: podcastTitle,
                                playbackDurationString: durationString,
                                playbackURL: item.enclosure?.attributes?.url ?? ""
                            )
                            episodes.append(episode)
                        }
                    }
                    
                    // Erstelle ein neues Podcast-Objekt mit den neuen Episoden
                    var updatedPodcast = podcast
                    updatedPodcast.episodes = episodes  // Aktualisiere das Podcast-Objekt mit den neuen Episoden
                    
                    completion(updatedPodcast, episodes) // Rückgabe des aktualisierten Podcasts und der Episoden
                    
                case .atom, .json:
                    print("Nicht unterstütztes Feed-Format")
                    completion(podcast, [])
                }
                
            case .failure(let error):
                print("Fehler beim Parsen des Feeds: \(error)")
                completion(podcast, [])
            }
        }
    }
    
    // Funktion zum Konvertieren der Dauer in TimeInterval
    static func parseTimeInterval(_ duration: Any?) -> TimeInterval {
        switch duration {
        case let string as String:
            // Verarbeite String-Eingaben
            let components = string.components(separatedBy: ":")
            var interval: TimeInterval = 0
            for (index, component) in components.reversed().enumerated() {
                if let value = Double(component) {
                    interval += value * pow(60, Double(index))
                }
            }
            return interval
        case let number as NSNumber:
            // Verarbeite numerische Eingaben
            return number.doubleValue
        default:
            return 0
        }
    }
}

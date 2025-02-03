import Foundation
import FeedKit
import UIKit

class PodcastFetcher: ObservableObject {
    
    @Published var podcasts: [Podcast] = []

    // 🎙️ Podcast-Modell
    public struct Podcast: Identifiable {
        let id: String
        let name: String
        let feedURL: String
        let artworkFilePath: String?
        var episodes: [PodcastEpisode] = [] 
    }
    
    // 🎧 Podcast-Episoden-Modell
    struct PodcastEpisode: Identifiable {
        let id: String
        let title: String
        let podcastName: String
        let playbackDurationString: String
        let playbackURL: String
    }

    // 🔍 Podcast-Suche per Apple API
    class PodcastSearchAPI {
        static func searchPodcasts(by query: String) async -> [Podcast] {
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            let urlString = "https://itunes.apple.com/search?media=podcast&entity=podcast&term=\(encodedQuery)&limit=15"

            guard let url = URL(string: urlString) else { return [] }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let results = json["results"] as? [[String: Any]] {
                    return results.compactMap { podcast in
                        guard let id = podcast["collectionId"] as? Int,
                              let name = podcast["collectionName"] as? String,
                              let rssURL = podcast["feedUrl"] as? String,
                              let artworkURL = podcast["artworkUrl100"] as? String else { return nil }

                        return Podcast(id: "\(id)", name: name, feedURL: rssURL, artworkFilePath: artworkURL) // ✅ Fix: Richtige Property-Namen
                    }
                }
            } catch {
                print("❌ Fehler beim Abrufen der Podcasts: \(error)")
            }
            return []
        }
    }

    // 🖼️ Podcast-Cover laden
    static func loadPodcastArtwork(for podcast: Podcast, completion: @escaping (UIImage?) -> Void) {
        guard let artworkPath = podcast.artworkFilePath, let url = URL(string: artworkPath) else {
            completion(nil)
            return
        }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let image = UIImage(data: data)
                completion(image)
            } catch {
                print("❌ Fehler beim Laden des Covers: \(error)")
                completion(nil)
            }
        }
    }
    
    // 📥 Lade Episoden für einen Podcast
    func fetchEpisodes(from feedURL: String, podcast: Podcast) async -> [PodcastEpisode] {
        print("🔍 Starte Episoden-Fetch für: \(podcast.name)")
        guard let url = URL(string: feedURL) else {
            print("❌ Ungültige Feed-URL: \(feedURL)")
            return []
        }
        
        let parser = FeedParser(URL: url)
        
        return await withCheckedContinuation { continuation in
            parser.parseAsync { result in
                switch result {
                case .success(let feed):
                    var episodes: [PodcastEpisode] = []
                    var podcastTitle: String = podcast.name
                    
                    switch feed {
                    case .rss(let rssFeed):
                        podcastTitle = rssFeed.title ?? podcast.name
                        
                        if let items = rssFeed.items {
                            print("✅ \(items.count) Episoden im Feed gefunden!")
                            for item in items {
                                let duration = PodcastFetcher.parseTimeInterval(item.iTunes?.iTunesDuration)
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
                        
                    case .atom, .json:
                        print("⚠️ Nicht unterstütztes Feed-Format für: \(podcast.name)")
                    }
                    
                    print("📥 \(episodes.count) Episoden für \(podcast.name) geladen!")
                    continuation.resume(returning: episodes)

                case .failure(let error):
                    print("❌ Fehler beim Parsen des Feeds für \(podcast.name): \(error)")
                    continuation.resume(returning: [])
                }
            }
        }
    }

    // 🕒 Konvertiere Dauer
    static func parseTimeInterval(_ duration: Any?) -> TimeInterval {
        switch duration {
        case let string as String:
            let components = string.components(separatedBy: ":")
            var interval: TimeInterval = 0
            for (index, component) in components.reversed().enumerated() {
                if let value = Double(component) {
                    interval += value * pow(60, Double(index))
                }
            }
            return interval
        case let number as NSNumber:
            return number.doubleValue
        default:
            return 0
        }
    }
}

import Foundation
import CloudKit
import FeedKit

class PodcastInfoHandler {
    
    private static func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private static func getPodcastsDirectory() -> URL {
        let podcastsDir = getDocumentsDirectory().appendingPathComponent("Podcasts", isDirectory: true)
        try? FileManager.default.createDirectory(at: podcastsDir, withIntermediateDirectories: true, attributes: nil)
        return podcastsDir
    }
    
    private static func podcastPath(for podcastID: String) -> URL {
        return getPodcastsDirectory().appendingPathComponent("\(podcastID).txt")
    }
    
    static func savePodcast(feedURL: String) {
        guard let url = URL(string: feedURL) else {
            print("Fehler: Ungültige URL")
            return
        }
        print("Versuche, Feed zu parsen: \(feedURL)")

        let parser = FeedParser(URL: url)
        parser.parseAsync { result in
            switch result {
            case .success(let feed):
                var podcastTitle = "Unbekannter Podcast"
                var artworkURL: String? = nil
                print("Feed erfolgreich geparsed!")

                switch feed {
                case .rss(let rssFeed):
                    podcastTitle = rssFeed.title ?? "Unbekannter Podcast"
                    artworkURL = rssFeed.iTunes?.iTunesImage?.attributes?.href
                    print("Podcast Titel gefunden: \(podcastTitle)")

                    let podcastID = UUID().uuidString
                    let filePath = podcastPath(for: podcastID)
                    print("Speichere Podcast in: \(filePath.path)")

                    do {
                        let podcastData: [String: Any] = [
                            "id": podcastID,
                            "title": podcastTitle,
                            "rssFeedURL": feedURL,
                            "artworkURL": artworkURL ?? ""
                        ]
                        let jsonData = try JSONSerialization.data(withJSONObject: podcastData, options: .prettyPrinted)
                        try jsonData.write(to: filePath)
                        print("Podcast erfolgreich gespeichert!")
                    } catch {
                        print("Fehler beim Speichern des Podcasts: \(error)")
                    }

                case .atom, .json:
                    print("Nicht unterstütztes Feed-Format")
                }
            case .failure(let error):
                print("Fehler beim Parsen des Feeds: \(error)")
            }
        }
    }
    
    static func getPodcasts() async -> [PodcastFetcher.Podcast] {
        let podcastsDir = getPodcastsDirectory()
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(at: podcastsDir, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
            print("Fehler beim Auflisten der Podcast-Dateien")
            return []
        }
        
        return await withTaskGroup(of: PodcastFetcher.Podcast?.self) { group in
            for case let fileURL as URL in enumerator {
                group.addTask {
                    guard let data = try? Data(contentsOf: fileURL),
                          let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                          let id = dict["id"] as? String,
                          let title = dict["title"] as? String,
                          let rssFeedURL = dict["rssFeedURL"] as? String else {
                        return nil
                    }
                    
                    var artworkData: Data? = nil
                    if let artworkURL = dict["artworkURL"] as? String, let url = URL(string: artworkURL) {
                        do {
                            let (data, _) = try await URLSession.shared.data(from: url)
                            artworkData = data
                        } catch {
                            print("Fehler beim Laden des Bildes: \(error)")
                        }
                    }
                    
                    return PodcastFetcher.Podcast(
                        id: id,
                        name: title,
                        artworkData: artworkData,
                        rssFeedURL: rssFeedURL
                    )
                }
            }
            
            var podcasts: [PodcastFetcher.Podcast] = []
            for await podcast in group {
                if let podcast = podcast {
                    podcasts.append(podcast)
                }
            }
            return podcasts
        }
    }
}

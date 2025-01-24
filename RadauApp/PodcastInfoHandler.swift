import Foundation
import CloudKit
import FeedKit

class PodcastInfoHandler {
    
    
    
    // Pfad zum Speichern der Podcasts
    private static func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private static func podcastPath(for podcastID: String) -> URL {
        return getDocumentsDirectory().appendingPathComponent("Podcasts.txt")
    }
    
    
    // Speichern eines Podcasts mit Identifier und URL
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
                    artworkURL = rssFeed.iTunes?.iTunesImage?.attributes?.href // Die URL des Artwork-Bildes
                    print("Podcast Titel gefunden: \(podcastTitle)")

                    // Pfad zur Datei "Podcasts.txt" im Dokumentenverzeichnis
                    let fileManager = FileManager.default
                    let filePath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Podcasts.txt")
                    print("Speichere Podcast in: \(filePath.path)")

                    do {
                        let podcastData: [String: Any] = [
                            "id": UUID().uuidString,
                            "title": podcastTitle,
                            "rssFeedURL": feedURL,
                            "artworkURL": artworkURL ?? "" // Speichern der Artwork-URL
                        ]
                        let jsonData = try JSONSerialization.data(withJSONObject: [podcastData], options: []) // Packe in ein Array

                        if fileManager.fileExists(atPath: filePath.path) {
                            // Datei existiert, anfügen
                            let fileHandle = try FileHandle(forWritingTo: filePath)
                            fileHandle.seekToEndOfFile() // Setzt den FileHandle an das Ende der Datei
                            fileHandle.write(jsonData)  // Daten ans Ende der Datei anfügen
                            fileHandle.closeFile()
                            print("Neuer Podcast erfolgreich angehängt!")
                        } else {
                            // Datei existiert nicht, erstellen
                            try jsonData.write(to: filePath)
                            print("Podcast erfolgreich gespeichert!")
                        }
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
    
    
    
    // Abrufen der Podcasts aus der Datei und Parsen des Textes
    static func getPodcasts() async -> [PodcastFetcher.Podcast] {
        let fileManager = FileManager.default
        let filePath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Podcasts.txt")
        print("Versuche, Podcasts aus der Datei zu laden: \(filePath.path)")

        do {
            let fileContents = try String(contentsOf: filePath)
            print("Dateiinhalt: \(fileContents)")

            // Dateiinhalt als JSON konvertieren
            guard let data = fileContents.data(using: .utf8),
                  let podcastArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] else {
                print("Fehler bei der Konvertierung der Datei oder beim Parsen des JSONs")
                return []
            }

            print("Podcasts erfolgreich geladen")

            return await withTaskGroup(of: PodcastFetcher.Podcast?.self) { group in
                for dict in podcastArray {
                    group.addTask {
                        guard let id = dict["id"] as? String,
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
        } catch {
            print("Fehler beim Laden der Podcasts: \(error)")
            return []
        }
    }
}

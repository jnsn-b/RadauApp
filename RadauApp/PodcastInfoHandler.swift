import Foundation
import CloudKit
import FeedKit

class PodcastInfoHandler {
    
    private static func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private static func getPodcastsDirectory() -> URL {
        let podcastsDir = getDocumentsDirectory().appendingPathComponent("Podcasts", isDirectory: true)

        print("📂 Podcast-Verzeichnis: \(podcastsDir.path)")

        if !FileManager.default.fileExists(atPath: podcastsDir.path) {
            do {
                try FileManager.default.createDirectory(at: podcastsDir, withIntermediateDirectories: true, attributes: nil)
                print("📂 Verzeichnis erstellt: \(podcastsDir.path)")
            } catch {
                print("❌ Fehler beim Erstellen des Verzeichnisses: \(error)")
            }
        }

        return podcastsDir
    }
    
    static func savePodcast(name: String, feedURL: String, artworkURL: String?) async {
        let podcastID = UUID().uuidString
        let fileURL = getPodcastsDirectory().appendingPathComponent("\(podcastID).json")
        let artworkFileName = "\(podcastID).jpg"  // ✅ Nur Dateiname speichern
        let localArtworkPath = getPodcastsDirectory().appendingPathComponent(artworkFileName)

        let podcastData: [String: Any] = [
            "id": podcastID,
            "name": name,
            "feedURL": feedURL,
            "artworkFileName": artworkFileName // ✅ Nur den Dateinamen speichern
        ]

        if let artworkURL = artworkURL, let url = URL(string: artworkURL), url.scheme == "https" {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                try data.write(to: localArtworkPath) // ✅ Speichere das Bild lokal
                print("✅ Cover gespeichert unter: \(localArtworkPath.path)")
            } catch {
                print("❌ Fehler beim Laden des Covers: \(error)")
            }
        } else {
            print("⚠️ Keine gültige Web-URL für das Cover, wird nicht heruntergeladen.")
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: podcastData, options: .prettyPrinted)
            try jsonData.write(to: fileURL)
            print("✅ Podcast gespeichert als JSON: \(fileURL.path)")
        } catch {
            print("❌ Fehler beim Speichern des Podcasts: \(error)")
        }
    }
    
    static func getPodcasts() async -> [PodcastFetcher.Podcast] {
        let podcastsDir = getPodcastsDirectory()
        let fileManager = FileManager.default

        
        
        print("📂 Lade gespeicherte Podcasts aus: \(podcastsDir.path)")

        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: podcastsDir, includingPropertiesForKeys: nil)
            let jsonFiles = fileURLs.filter { $0.pathExtension == "json" } // ✅ Nur JSON-Dateien verarbeiten

            print("📂 Gefundene JSON-Dateien: \(jsonFiles.map { $0.lastPathComponent })")

            return await withTaskGroup(of: PodcastFetcher.Podcast?.self) { group in
                for fileURL in jsonFiles {
                    print("🔍 Verarbeite JSON-Datei: \(fileURL.lastPathComponent)")

                    group.addTask {
                        do {
                            let data = try Data(contentsOf: fileURL)
                            print("📄 JSON-Inhalt für \(fileURL.lastPathComponent): \(String(data: data, encoding: .utf8) ?? "Fehler beim Lesen")")

                            guard let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                                print("⚠️ Konnte JSON nicht deserialisieren: \(fileURL.path)")
                                return nil
                            }

                            guard let id = dict["id"] as? String,
                                  let name = dict["name"] as? String,
                                  let feedURL = dict["feedURL"] as? String else {
                                print("⚠️ Fehlerhafte Podcast-Daten in Datei: \(fileURL.lastPathComponent)")
                                return nil
                            }

                            var artworkFilePath: String? = nil
                            if let storedArtworkFileName = dict["artworkFileName"] as? String, !storedArtworkFileName.isEmpty {
                                let reconstructedPath = getPodcastsDirectory().appendingPathComponent(storedArtworkFileName).path
                                if FileManager.default.fileExists(atPath: reconstructedPath) {
                                    print("✅ Cover gefunden: \(reconstructedPath)")
                                    artworkFilePath = reconstructedPath
                                } else {
                                    print("⚠️ Cover nicht gefunden für Podcast \(name): \(reconstructedPath)")
                                }
                            }

                            return PodcastFetcher.Podcast(
                                id: id,
                                name: name,
                                feedURL: feedURL,
                                artworkFilePath: artworkFilePath
                            )
                        } catch {
                            print("❌ Fehler beim Laden des Podcasts \(fileURL.lastPathComponent): \(error)")
                            return nil
                        }
                    }
                }

                var podcasts: [PodcastFetcher.Podcast] = []
                for await podcast in group {
                    if let podcast = podcast {
                        podcasts.append(podcast)
                    }
                }
                print("✅ Geladene Podcasts: \(podcasts.count)")
                return podcasts
            }
        } catch {
            print("❌ Fehler beim Laden der Podcast-Verzeichnisse: \(error)")
            return []
        }
    }

}


    /* ALTE LÖSUNG  static func savePodcast(feedURL: String) {
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
      } */

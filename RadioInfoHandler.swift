import Foundation

class RadioInfoHandler {
    
    /// Gibt das Dokumentenverzeichnis der App zurück
    private static func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    /// Erstellt (falls nicht vorhanden) und gibt den "Radio"-Ordner im Dokumentenverzeichnis zurück
    
    private static func getRadiosDirectory() -> URL {
        let radiosDir = getDocumentsDirectory().appendingPathComponent("Radio", isDirectory: true)
        let fileManager = FileManager.default
        
        // Prüfe, ob der Ordner existiert, und erstelle ihn, falls nicht
        if !fileManager.fileExists(atPath: radiosDir.path) {
            do {
                try fileManager.createDirectory(at: radiosDir, withIntermediateDirectories: true, attributes: nil)
                print("📁 Ordner 'Radio' wurde erstellt: \(radiosDir.path)")
            } catch {
                print("❌ Fehler beim Erstellen des 'Radio'-Ordners: \(error)")
            }
        }
        
        return radiosDir
    }
    
    public static func getPublicRadiosDirectory() -> URL {
        return getRadiosDirectory() // Gibt den privaten Pfad zurück
    }
    
    /// Gibt den Pfad für eine bestimmte Radio-Stream-Datei basierend auf der ID zurück
    private static func radioPath(for radioID: String) -> URL {
        return getRadiosDirectory().appendingPathComponent("\(radioID).json")
    }
    
    /// Speichert einen Radiosender in einer JSON-Datei im "Radio"-Ordner
    static func saveRadio(id: String? = nil, name: String, streamURL: String, artworkURL: String?) async {
        let radioID = id ?? UUID().uuidString // Falls keine ID übergeben wurde, neue generieren
        let fileURL = getRadiosDirectory().appendingPathComponent("\(radioID).json")
        let artworkFileName = "\(radioID).jpg"
        let localArtworkPath = getRadiosDirectory().appendingPathComponent(artworkFileName)

        var radioData: [String: Any] = [
            "id": radioID,
            "name": name,
            "streamURL": streamURL
        ]

        if let artworkURL = artworkURL, let url = URL(string: artworkURL), url.scheme == "https" {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                try data.write(to: localArtworkPath)
                print("✅ Radio-Icon gespeichert unter: \(localArtworkPath.path)")

                radioData["artworkFileName"] = artworkFileName // ✅ Speichere nur Dateinamen
            } catch {
                print("❌ Fehler beim Laden des Radio-Icons: \(error)")
            }
        } else {
            print("⚠️ Keine gültige Web-URL für das Radio-Icon, wird nicht heruntergeladen.")
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: radioData, options: .prettyPrinted)
            try jsonData.write(to: fileURL)
            print("✅ Radiosender gespeichert als JSON: \(fileURL.path)")
        } catch {
            print("❌ Fehler beim Speichern des Radiosenders: \(error)")
        }
    }
    
    /// Lädt alle gespeicherten Radiosender aus dem "Radio"-Ordner und gibt eine Liste zurück
    static func getRadios() async -> [Radio] {
        let radiosDir = getRadiosDirectory()
        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(at: radiosDir, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
            print("❌ Fehler beim Auflisten der Radio-Dateien")
            return []
        }

        return await withTaskGroup(of: Radio?.self) { group in
            for case let fileURL as URL in enumerator {
                group.addTask {
                    guard let data = try? Data(contentsOf: fileURL),
                          let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                          let id = dict["id"] as? String,
                          let name = dict["name"] as? String,
                          let streamURL = dict["streamURL"] as? String else {
                        return nil
                    }

                    // ✅ Automatisch den Bildpfad aus der ID generieren
                    let artworkFilePath = getRadiosDirectory().appendingPathComponent("\(id).jpg").path
                    
                    if FileManager.default.fileExists(atPath: artworkFilePath) {
                        print("✅ Radio-Icon gefunden: \(artworkFilePath)")
                    } else {
                        print("⚠️ Radio-Icon nicht gefunden für \(name): \(artworkFilePath)")
                    }

                    return Radio(
                        id: id,
                        name: name,
                        streamURL: streamURL,
                        artworkData: nil,
                        artworkFilePath: FileManager.default.fileExists(atPath: artworkFilePath) ? artworkFilePath : nil
                    )
                }
            }

            var radios: [Radio] = []
            for await radio in group {
                if let radio = radio {
                    radios.append(radio)
                }
            }
            return radios
        }
    }
    
    static func searchRadios(by name: String) async -> [Radio] {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        let urlString = "https://de1.api.radio-browser.info/json/stations/byname/\(encodedName)?hidebroken=true"

        guard let url = URL(string: urlString) else { return [] }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                return await withTaskGroup(of: Radio?.self) { group in
                    for station in jsonArray {
                        group.addTask {
                            guard let id = station["stationuuid"] as? String,
                                  let name = station["name"] as? String,
                                  let streamURL = station["url_resolved"] as? String else { return nil }

                            let logoURL = station["favicon"] as? String ?? ""
                            var artworkData: Data? = nil

                            // ✅ Bild wird nur in-memory gespeichert, NICHT als Datei
                            if !logoURL.isEmpty, let url = URL(string: logoURL) {
                                do {
                                    let (data, _) = try await URLSession.shared.data(from: url)
                                    artworkData = data
                                } catch {
                                    print("⚠️ Fehler beim Laden des Logos für \(name): \(error)")
                                }
                            }

                            return Radio(id: id, name: name, streamURL: streamURL, artworkData: artworkData, artworkFilePath: nil) // ❌ KEINE Speicherung in Datei
                        }
                    }

                    var radios: [Radio] = []
                    for await radio in group {
                        if let radio = radio {
                            radios.append(radio)
                        }
                    }
                    return radios
                }
            }
        } catch {
            print("❌ Fehler beim Abrufen der Radiosender: \(error)")
        }
        return []
    }
}


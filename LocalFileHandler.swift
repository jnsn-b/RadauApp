import Foundation

class LocalFileHandler {
    static let shared = LocalFileHandler()

    private let fileManager = FileManager.default

    private init() {}

    // Speichert eine Datei (z.B. ein Bild) im Dokumentenverzeichnis der App
    // - Parameter fileName: Der Name der Datei, die gespeichert werden soll
    // - Parameter content: Die Daten, die gespeichert werden sollen
    // - Returns: Boolean-Wert, der den Erfolg des Speichervorgangs anzeigt
    func saveFile(fileName: String, content: Data) -> Bool {
        // Zugriff auf das Dokumentenverzeichnis der App
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }

        let fileURL = documentsDirectory.appendingPathComponent(fileName)

        do {
            // Versucht, die Daten zu schreiben und gibt den Erfolg zurück
            try content.write(to: fileURL)
            return true
        } catch {
            // Fehlerbehandlung, falls das Speichern fehlschlägt
            return false
        }
    }

    // Lädt eine Datei aus dem Dokumentenverzeichnis der App
    // - Parameter fileName: Der Name der Datei, die geladen werden soll
    // - Returns: Die geladenen Daten oder nil, falls das Laden fehlschlägt
    func loadFile(fileName: String) -> Data? {
        // Zugriff auf das Dokumentenverzeichnis der App
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let fileURL = documentsDirectory.appendingPathComponent(fileName)

        do {
            // Versucht, die Daten von der Datei zu lesen
            let data = try Data(contentsOf: fileURL)
            return data
        } catch {
            // Fehlerbehandlung, falls das Laden fehlschlägt
            return nil
        }
    }

    // Lädt alle Dateien aus dem Dokumentenverzeichnis und gibt eine Liste von Dateinamen zurück
    // - Returns: Eine Liste der Dateinamen oder ein leerer Array, falls keine Dateien gefunden wurden
    func listAllFiles() -> [String] {
        // Zugriff auf das Dokumentenverzeichnis der App
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return []
        }

        do {
            // Ruft die Inhalte des Verzeichnisses ab
            let files = try fileManager.contentsOfDirectory(atPath: documentsDirectory.path)
            return files
        } catch {
            // Fehlerbehandlung, falls das Lesen des Verzeichnisses fehlschlägt
            return []
        }
    }
}

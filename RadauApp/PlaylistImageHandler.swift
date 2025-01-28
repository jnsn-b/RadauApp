import Foundation
import SwiftUI

class PlaylistImageHandler {
    static let shared = PlaylistImageHandler() // Singleton für globalen Zugriff

    private init() { }

    // Pfad zum Speichern der Bilder
    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private func imagePath(for playlistID: UInt64) -> URL {
        return getDocumentsDirectory().appendingPathComponent("\(playlistID).png")
    }

    // Bild skalieren
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        let scaleFactor = min(widthRatio, heightRatio)

        let scaledSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)

        UIGraphicsBeginImageContextWithOptions(scaledSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: scaledSize))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }

    // Speichern des Bildes im Dateisystem und in UserDefaults
    func saveImage(_ image: UIImage, for playlistID: UInt64) {
        let resizedImage = resizeImage(image: image, targetSize: CGSize(width: 80, height: 80))
        let fileName = "\(playlistID).png" // Der Dateiname
        let url = getDocumentsDirectory().appendingPathComponent(fileName) // Der vollständige Pfad für Speicherung

        if let data = resizedImage.pngData() {
            try? data.write(to: url)

            // Speichern nur des Dateinamens in UserDefaults
            var savedPaths = UserDefaults.standard.dictionary(forKey: "playlistImages") as? [String: String] ?? [:]
            savedPaths[String(playlistID)] = fileName  // Speichern nur des Dateinamens, nicht des kompletten Pfads
            UserDefaults.standard.set(savedPaths, forKey: "playlistImages")
        }
    }


    // Alle gespeicherten Bilder laden
    func loadAllImages() -> [UInt64: UIImage] {
        var images: [UInt64: UIImage] = [:]
        
        // Holen der gespeicherten Pfade aus UserDefaults
        let savedPaths = UserDefaults.standard.dictionary(forKey: "playlistImages") as? [String: String] ?? [:]

        // Base-URL für das Documents-Verzeichnis
        let documentsDirectory = getDocumentsDirectory()

        for (key, fileName) in savedPaths {
            if let playlistID = UInt64(key) {
                // Rekonstruiere den vollständigen Pfad, indem nur der Dateiname genutzt wird
                let filePath = documentsDirectory.appendingPathComponent(fileName)

                if let image = UIImage(contentsOfFile: filePath.path) {
                    images[playlistID] = image
                } else {
                    print("❌ Bild für Playlist \(playlistID) konnte nicht geladen werden: \(filePath.path)")
                }
            }
        }

        return images
    }
}

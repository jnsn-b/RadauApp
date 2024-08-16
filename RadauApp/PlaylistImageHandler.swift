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

    // Speichern des Bildes im Dateisystem und in UserDefaults
    func saveImage(_ image: UIImage, for playlistID: UInt64) {
        let url = imagePath(for: playlistID)

        if let data = image.pngData() {
            try? data.write(to: url)

            var savedPaths = UserDefaults.standard.dictionary(forKey: "playlistImages") as? [String: String] ?? [:]
            savedPaths[String(playlistID)] = url.path
            UserDefaults.standard.set(savedPaths, forKey: "playlistImages")
        }
    }

    // Laden eines Bildes für eine bestimmte Playlist
    func loadImage(for playlistID: UInt64) -> UIImage? {
        let path = UserDefaults.standard.dictionary(forKey: "playlistImages") as? [String: String] ?? [:]
        if let imagePath = path[String(playlistID)],
           let data = try? Data(contentsOf: URL(fileURLWithPath: imagePath)) {
            return UIImage(data: data)
        }
        return nil
    }

    // Laden aller gespeicherten Bilder
    func loadAllImages() -> [UInt64: UIImage] {
        var images: [UInt64: UIImage] = [:]
        let savedPaths = UserDefaults.standard.dictionary(forKey: "playlistImages") as? [String: String] ?? [:]

        for (playlistIDString, path) in savedPaths {
            if let playlistID = UInt64(playlistIDString),
               let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
               let image = UIImage(data: data) {
                images[playlistID] = image
            }
        }
        return images
    }
}

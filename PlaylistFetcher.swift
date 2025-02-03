import Foundation
import MediaPlayer

// Klasse zum Abrufen von Playlists aus der Media Library
class PlaylistFetcher: ObservableObject {
    // Eine veröffentlichte Eigenschaft, die eine Liste von Playlists enthält
    @Published var playlists: [MPMediaPlaylist] = []
    
    // Funktion zum Abrufen der Playlists aus der Media Library
    func fetchPlaylists() {
           let query = MPMediaQuery.playlists()
           
           // ✅ Sicherstellen, dass `query.collections` gültig ist
           guard let collections = query.collections else {
               print("⚠️ Keine Playlists gefunden!")
               self.playlists = []
               return
           }

           // ✅ Sicherstellen, dass jede Collection wirklich eine MPMediaPlaylist ist
           let validPlaylists = collections.compactMap { $0 as? MPMediaPlaylist }

           // ✅ Herausfiltern von leeren Playlisten
           let filteredPlaylists = validPlaylists.filter { $0.items.count > 0 }

           DispatchQueue.main.async {
               self.playlists = filteredPlaylists
           }
       }
}


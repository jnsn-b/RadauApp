import Foundation
import MediaPlayer

// Klasse zum Abrufen von Playlists aus der Media Library
class PlaylistFetcher: ObservableObject {
    // Eine veröffentlichte Eigenschaft, die eine Liste von Playlists enthält
    @Published var playlists: [MPMediaPlaylist] = []
    
    // Funktion zum Abrufen der Playlists aus der Media Library
    func fetchPlaylists() {
        // Erstellen einer Abfrage, um alle Playlists abzurufen
        let query = MPMediaQuery.playlists()
        
        // Überprüfen, ob die Abfrage gültige Playlists zurückgegeben hat
        if let playlists = query.collections as? [MPMediaPlaylist] {
            // Aktualisieren der veröffentlichten Eigenschaft auf dem Hauptthread
            DispatchQueue.main.async {
                self.playlists = playlists
            }
        } else {
            // Fehlerbehandlung, falls keine Playlists gefunden wurden
            DispatchQueue.main.async {
                self.playlists = [] // Setzt die Playlists-Liste auf leer, falls keine gefunden werden
            }
        }
    }
}



import Foundation
import MediaPlayer

class PlaylistFetcher: ObservableObject {
    @Published var playlists: [MPMediaPlaylist] = []
    
    func fetchPlaylists() {
        let query = MPMediaQuery.playlists()
        if let playlists = query.collections as? [MPMediaPlaylist] {
            DispatchQueue.main.async {
                self.playlists = playlists
            }
        }
    }
}

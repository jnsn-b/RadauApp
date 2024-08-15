import SwiftUI
import MusicKit

struct PlaylistDetailView: View {
    var songs: [Song] // Verwendet eine Liste von Songs
    @StateObject var playerManager = MusicPlayerManager()

    var body: some View {
        List(songs, id: \.id) { track in
            Button(action: {
                playerManager.play(song: track)
            }) {
                VStack(alignment: .leading) {
                    Text(track.title ?? "Unbekannter Titel")
                        .font(.headline)
                    Text(track.artistName ?? "Unbekannter Künstler")
                        .font(.subheadline)
                }
            }
        }
        .navigationTitle("Playlist") // Verwende einen statischen Titel
        .sheet(item: $playerManager.currentSong) { _ in
            MusicPlayerView(playerManager: playerManager)
        }
    }
}

import SwiftUI
import MediaPlayer

struct ParentsView: View {
    @Binding var playlists: [MPMediaPlaylist]
    @Binding var selectedPlaylists: Set<MPMediaEntityPersistentID>

    var body: some View {
        VStack {
            Text("Elternbereich")
                .font(.largeTitle)
                .padding()

            NavigationLink(destination: PlaylistSelectionView(playlists: $playlists, selectedPlaylists: $selectedPlaylists)) {
                Text("Playlist-Auswahl")
                    .foregroundColor(.blue)
                    .font(.headline)
            }
            .padding()
            
            Spacer()
        }
        .navigationTitle("Einstellungen")
    }
}

struct ParentsView_Previews: PreviewProvider {
    @State static var playlists: [MPMediaPlaylist] = []
    @State static var selectedPlaylists: Set<MPMediaEntityPersistentID> = []

    static var previews: some View {
        ParentsView(playlists: $playlists, selectedPlaylists: $selectedPlaylists)
    }
}

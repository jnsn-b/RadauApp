import SwiftUI
import MediaPlayer

struct PlaylistSelectionView: View {
    @Binding var playlists: [MPMediaPlaylist]
    @Binding var selectedPlaylists: Set<MPMediaEntityPersistentID>
    @Environment(\.presentationMode) var presentationMode  // Präsentationsmodus-Umgebung

    var body: some View {
        VStack(alignment: .leading) {
            List {
                ForEach(playlists, id: \.persistentID) { playlist in
                    Button(action: {
                        if selectedPlaylists.contains(playlist.persistentID) {
                            selectedPlaylists.remove(playlist.persistentID)
                        } else {
                            selectedPlaylists.insert(playlist.persistentID)
                        }
                    }) {
                        HStack {
                            Text(playlist.name ?? "Unbekannte Playlist")
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedPlaylists.contains(playlist.persistentID) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())

            Spacer()
        }
        .navigationTitle("Playlist-Auswahl")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Fertig") {
                    presentationMode.wrappedValue.dismiss()  // Manuelles Schließen der Ansicht
                }
            }
        }
    }
}

struct PlaylistSelectionView_Previews: PreviewProvider {
    @State static var playlists: [MPMediaPlaylist] = []
    @State static var selectedPlaylists: Set<MPMediaEntityPersistentID> = []

    static var previews: some View {
        PlaylistSelectionView(playlists: $playlists, selectedPlaylists: $selectedPlaylists)
    }
}

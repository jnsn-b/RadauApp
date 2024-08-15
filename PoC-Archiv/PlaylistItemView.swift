import SwiftUI
import MusicKit
import MediaPlayer

struct PlaylistItemView: View {
    let playlist: MPMediaPlaylist
    let musicPlayer: ApplicationMusicPlayer

    var body: some View {
        NavigationLink(destination: PlaylistDetailView(playlist: playlist, musicPlayer: musicPlayer)) {
            VStack {
                if let artwork = playlist.artwork?.url(width: 100, height: 100) {
                    AsyncImage(url: artwork) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .cornerRadius(15)
                    } placeholder: {
                        Image(systemName: "music.note.list")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .cornerRadius(15)
                    }
                } else {
                    Image(systemName: "music.note.list")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .cornerRadius(15)
                }
                Text(playlist.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding()
            .frame(width: 120, height: 150)
            .background(Color.blue)
            .cornerRadius(15)
            .shadow(radius: 5)
        }
    }
}

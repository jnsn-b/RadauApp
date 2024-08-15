import SwiftUI
import MediaPlayer

class MiniPlayerManager: ObservableObject {
    @Published var showMiniPlayer: Bool = false
    @Published var showPlayer: Bool = false
    var musicPlayer = MusicPlayer()
    
    func minimizePlayer() {
        withAnimation {
            showMiniPlayer = true
            showPlayer = false
        }
    }
    
    func maximizePlayer() {
        withAnimation {
            showMiniPlayer = false
            showPlayer = true
        }
    }
    
    func togglePlayer() {
        if showPlayer {
            minimizePlayer()
        } else {
            maximizePlayer()
        }
    }
}

struct ScreenPainter {
    static let miniPlayerManager = MiniPlayerManager()

    static func applyCardStyle(to view: AnyView) -> AnyView {
        AnyView(
            view
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: .gray, radius: 5, x: 0, y: 2)
                .padding([.leading, .trailing], 8)
        )
    }
    
    static func artworkView(for artwork: MPMediaItemArtwork?, size: CGSize) -> some View {
        Group {
            if let artwork = artwork {
                Image(uiImage: artwork.image(at: size) ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size.width, height: size.height)
                    .cornerRadius(10)
            } else {
                Image(systemName: "music.note")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size.width, height: size.height)
                    .cornerRadius(10)
            }
        }
    }

    static func playlistCardView(for playlist: MPMediaPlaylist) -> some View {
        NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
            VStack {
                if let artwork = playlist.representativeItem?.artwork {
                    Image(uiImage: artwork.image(at: CGSize(width: 100, height: 100)) ?? UIImage())
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .cornerRadius(10)
                } else {
                    Image(systemName: "music.note.list")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .cornerRadius(10)
                }
                
                Text(playlist.name ?? "Unbenannte Playlist")
                    .font(.headline)
                    .lineLimit(1)
                    .padding([.leading, .trailing, .bottom], 5)
            }
            .frame(width: UIScreen.main.bounds.width / 2 - 24, height: 150)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(10)
            .shadow(color: .gray, radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    static func renderMiniPlayer() -> some View {
        if miniPlayerManager.showMiniPlayer {
            return AnyView(
                MiniPlayerView(musicPlayer: miniPlayerManager.musicPlayer)
                    .onTapGesture {
                        miniPlayerManager.maximizePlayer() // Wechsel zurück zum Vollbild-Player bei Tap
                    }
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: miniPlayerManager.showMiniPlayer)
            )
        } else {
            return AnyView(EmptyView())
        }
    }
}

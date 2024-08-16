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

class ScreenPainter: ObservableObject {
    static let miniPlayerManager = MiniPlayerManager()
    
    @Published var playlistImages: [UInt64: UIImage] = [:]

    init() {
        loadImages()
    }

    func loadImages() {
        playlistImages = PlaylistImageHandler.shared.loadAllImages()
    }

    func updateImage(for playlist: MPMediaPlaylist, image: UIImage?) {
        if let image = image {
            playlistImages[playlist.persistentID] = image
            PlaylistImageHandler.shared.saveImage(image, for: playlist.persistentID)
        }
    }

    // Farb-Schema
    static var primaryColor: Color = Color(hex: "#275457")
    static var secondaryColor: Color = .white
    static var backgroundColor: Color = Color(hex: "#60B2B8")
    static var textColor: Color = .white
    
    // Schriftarten
    static var titleFont: Font = .headline
    static var bodyFont: Font = .body

    // Button-Stile
    static func primaryButtonStyle() -> some View {
        return Group {
            Text("Button")
                .padding()
                .background(primaryColor)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }

    // Player-Steuerelemente
    static func playerControlButtonStyle() -> some View {
        return Group {
            Text("Control")
                .padding()
                .background(secondaryColor)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }

    // Anpassung von Kartenstilen
    static func applyCardStyle(to view: AnyView) -> AnyView {
        AnyView(
            view
                .background(backgroundColor)
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
                if let customImage = ScreenPainter().playlistImages[playlist.persistentID] {
                    Image(uiImage: customImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .cornerRadius(10)
                } else if let artwork = getBestArtwork(for: playlist) {
                    artworkView(for: artwork, size: CGSize(width: 100, height: 100))
                } else {
                    Image(systemName: "music.note.list")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .cornerRadius(10)
                }
                
                Text(playlist.name ?? "Unbenannte Playlist")
                    .font(titleFont)
                    .foregroundColor(primaryColor)
                    .lineLimit(1)
                    .padding([.leading, .trailing, .bottom], 5)
            }
            .frame(width: UIScreen.main.bounds.width / 2 - 24, height: 150)
            .background(.white)
            .cornerRadius(10)
            .shadow(color: .gray, radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    static func getBestArtwork(for playlist: MPMediaPlaylist) -> MPMediaItemArtwork? {
        // Priorisiere das representativeItem der Playlist, da es das benutzerdefinierte Bild enthält
        if let representativeArtwork = playlist.representativeItem?.artwork {
            return representativeArtwork
        }
        
        // Wenn das nicht funktioniert, verwende das Artwork des ersten Songs
        return playlist.items.first?.artwork
    }

    static func renderMiniPlayer() -> some View {
        if miniPlayerManager.showMiniPlayer {
            return AnyView(
                MiniPlayerView(musicPlayer: miniPlayerManager.musicPlayer)
                    .onTapGesture {
                        miniPlayerManager.maximizePlayer()
                    }
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: miniPlayerManager.showMiniPlayer)
            )
        } else {
            return AnyView(EmptyView())
        }
    }
    
    // Möglichkeit zur Laufzeit Farb-Schema zu ändern
    static func updatePrimaryColor(to color: Color) {
        primaryColor = color
    }

    static func updateSecondaryColor(to color: Color) {
        secondaryColor = color
    }

    static func updateTextColor(to color: Color) {
        textColor = color
    }

    static func updateBackgroundColor(to color: Color) {
        backgroundColor = color
    }

    static func updateTitleFont(to font: Font) {
        titleFont = font
    }

    static func updateBodyFont(to font: Font) {
        bodyFont = font
    }
}

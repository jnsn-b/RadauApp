import SwiftUI
import MediaPlayer


// Klasse zur Verwaltung der Benutzeroberfläche und des Farbschemas
class ScreenPainter: ObservableObject {
    static let miniPlayerManager = MiniPlayerManager()
    
    @Published var playlistImages: [UInt64: UIImage] = [:]

    init() {
        loadImages()
    }

    // Funktion zum Laden aller gespeicherten Bilder für Playlists
    func loadImages() {
        playlistImages = PlaylistImageHandler.shared.loadAllImages()
    }

    // Funktion zum Aktualisieren des Bildes einer Playlist
    func updateImage(for playlist: MPMediaPlaylist, image: UIImage) {
        let playlistID = playlist.persistentID
        PlaylistImageHandler.shared.saveImage(image, for: playlistID)
        loadImages() // Lädt die Bilder neu, um die Aktualisierung zu reflektieren
    }

    // Farb-Schema und Schriftarten
    static var primaryColor: Color = Color(hex: "#275457")
    static var secondaryColor: Color = .white
    static var backgroundColor: Color = Color(hex: "#60B2B8")
    static var textColor: Color = .white
    static var titleFont: Font = .headline
    static var bodyFont: Font = .body

    // Funktion zum Erstellen eines Standard-Button-Stils
    static func primaryButtonStyle() -> some View {
        Text("Button")
            .padding()
            .background(primaryColor)
            .foregroundColor(.white)
            .cornerRadius(10)
    }

    // Funktion zum Erstellen eines Standard-Steuerknopf-Stils für den Player
    static func playerControlButtonStyle() -> some View {
        Text("Control")
            .padding()
            .background(secondaryColor)
            .foregroundColor(.white)
            .cornerRadius(8)
    }

    // Funktion zum Anwenden des Kartenstils auf eine beliebige Ansicht
    static func applyCardStyle(to view: AnyView) -> AnyView {
        AnyView(
            view
                .background(backgroundColor)
                .cornerRadius(10)
                .shadow(color: .gray, radius: 5, x: 0, y: 2)
                .padding([.leading, .trailing], 8)
        )
    }

    // Funktion zur Darstellung eines Artwork-Views für ein Musikstück
    static func artworkView(for artwork: MPMediaItemArtwork?, size: CGSize) -> some View {
        Group {
            if let artwork = artwork {
                Image(uiImage: artwork.image(at: size) ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .cornerRadius(10)
            } else {
                Image(systemName: "music.note")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .cornerRadius(10)
            }
        }
    }

    // Funktion zur Darstellung einer Playlist-Karte
    static func playlistCardView(for playlist: MPMediaPlaylist) -> some View {
        NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
            VStack {
                if let customImage = ScreenPainter().playlistImages[playlist.persistentID] {
                    Image(uiImage: customImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipped()
                        .cornerRadius(10)
                } else if let artwork = getBestArtwork(for: playlist) {
                    artworkView(for: artwork, size: CGSize(width: 100, height: 100))
                } else {
                    Image(systemName: "music.note.list")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
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
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: .gray, radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // Funktion zur Ermittlung des besten Artworks für eine Playlist
    static func getBestArtwork(for playlist: MPMediaPlaylist) -> MPMediaItemArtwork? {
        // Priorisiere das representativeItem der Playlist, da es das benutzerdefinierte Bild enthält
        if let representativeArtwork = playlist.representativeItem?.artwork {
            return representativeArtwork
        }
        // Verwende das Artwork des ersten Songs als Fallback
        return playlist.items.first?.artwork
    }

    // Funktion zur Darstellung des Mini-Players
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
    
    // Möglichkeit zur Laufzeit das Farb-Schema und die Schriftarten zu ändern
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

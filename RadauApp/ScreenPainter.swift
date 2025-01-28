import SwiftUI
import MediaPlayer

/// Klasse zur Verwaltung der Benutzeroberfläche und des Farbschemas
class ScreenPainter: ObservableObject {
    // MARK: - Properties
    
    /// Statische Instanz des MiniPlayerManagers
    static let miniPlayerManager = MiniPlayerManager()
    
    /// Published Property für Playlist-Bilder
    @Published var playlistImages: [UInt64: UIImage] = [:]

    // MARK: - Farbschema und Schriftarten
    
    /// Primärfarbe der Anwendung
    static var primaryColor: Color = Color(hex: "#275457")
    
    /// Sekundärfarbe der Anwendung
    static var secondaryColor: Color = .white
    
    /// Hintergrundfarbe der Anwendung
    static var backgroundColor: Color = Color(hex: "#60B2B8")
    
    /// Textfarbe der Anwendung
    static var textColor: Color = .white
    
    /// Schriftart für Überschriften
    static var titleFont: Font = .headline
    
    /// Schriftart für Fließtext
    static var bodyFont: Font = .body

    // MARK: - Initialisierung
    
    /// Initialisiert die ScreenPainter-Instanz und lädt die Bilder
    init() {
        loadImages()
    }

    // MARK: - Bild-Management

    /// Lädt alle gespeicherten Bilder für Playlists
    func loadImages() {
        playlistImages = PlaylistImageHandler.shared.loadAllImages()
    }

    /// Aktualisiert das Bild einer Playlist
    /// - Parameters:
    ///   - playlist: Die zu aktualisierende Playlist
    ///   - image: Das neue Bild für die Playlist
    func updateImage(for playlist: MPMediaPlaylist, image: UIImage) {
        let playlistID = playlist.persistentID
        PlaylistImageHandler.shared.saveImage(image, for: playlistID)
        
        DispatchQueue.main.async {
            self.playlistImages[playlistID] = image // Nur das eine Bild aktualisieren
        }
    }

    // MARK: - UI-Komponenten

    /// Erstellt einen Standard-Button-Stil
    /// - Returns: Eine View mit dem Standard-Button-Stil
    static func primaryButtonStyle() -> some View {
        Text("Button")
            .padding()
            .background(primaryColor)
            .foregroundColor(.white)
            .cornerRadius(10)
    }

    /// Erstellt einen Standard-Steuerknopf-Stil für den Player
    /// - Returns: Eine View mit dem Standard-Steuerknopf-Stil
    static func playerControlButtonStyle() -> some View {
        Text("Control")
            .padding()
            .background(secondaryColor)
            .foregroundColor(.white)
            .cornerRadius(8)
    }

   

    /// Erstellt eine Artwork-Ansicht für ein Musikstück
    /// - Parameters:
    ///   - artwork: Das Artwork des Musikstücks
    ///   - size: Die gewünschte Größe der Artwork-Ansicht
    /// - Returns: Eine View mit dem Artwork oder einem Platzhalter
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

    /// Erstellt eine Playlist-Karten-Ansicht
    /// - Parameter playlist: Die darzustellende Playlist
    /// - Returns: Eine View mit der Playlist-Karte
    static func playlistCardView(for playlist: MPMediaPlaylist) -> some View {
        NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
            mediaCardView(
                title: playlist.name ?? "Unbenannte Playlist",
                image: ScreenPainter().playlistImages[playlist.persistentID],
                placeholder: "music.note.list",
                size: CGSize(width: 100, height: 100)
            )
        }
    }

    /// Ermittelt das beste Artwork für eine Playlist
    /// - Parameter playlist: Die Playlist, für die das Artwork ermittelt werden soll
    /// - Returns: Das beste verfügbare Artwork oder nil
    static func getBestArtwork(for playlist: MPMediaPlaylist) -> MPMediaItemArtwork? {
        if let representativeArtwork = playlist.representativeItem?.artwork {
            return representativeArtwork
        }
        return playlist.items.first?.artwork
    }

    /// Rendert den Mini-Player
    /// - Returns: Eine View mit dem Mini-Player oder eine leere View
    static func renderMiniPlayer() -> some View {
        Group {
            if miniPlayerManager.showMiniPlayer {
                MiniPlayerView(musicPlayer: miniPlayerManager.musicPlayer)
                    .onTapGesture {
                        miniPlayerManager.maximizePlayer()
                    }
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: miniPlayerManager.showMiniPlayer)
            }
        }
    }
    
    /// Generische Methode für Playlist-, Podcast- und Radio-Karten
    /// Generische Methode für Playlist-, Podcast- und Radio-Karten mit weißem Hintergrund
    static func mediaCardView(title: String, image: UIImage?, placeholder: String, size: CGSize) -> some View {
        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)
                    .cornerRadius(10)
            } else {
                Image(systemName: placeholder)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)
                    .foregroundColor(.gray)
            }

            Text(title)
                .font(.headline)
                .foregroundColor(.black)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 4)
        }
        .frame(width: UIScreen.main.bounds.width / 2 - 24, height: 200) // Gleiche Breite wie Playlist-Karten
        .background(Color.white) // Kartenhintergrund auf Weiß setzen
        .cornerRadius(10)
        .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 2) // Schatten für bessere Optik
        .padding(10)
    }

    // MARK: - Hauptansichten

    /// Erstellt die Musik-Ansicht
    /// - Parameters:
    ///   - playlistFetcher: Der PlaylistFetcher zur Verwaltung der Playlists
    ///   - miniPlayerManager: Der MiniPlayerManager zur Steuerung des Players
    /// - Returns: Eine View mit der Musik-Ansicht
    static func musicView(playlistFetcher: PlaylistFetcher, miniPlayerManager: MiniPlayerManager) -> some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 40) {
                ForEach(playlistFetcher.playlists, id: \.persistentID) { playlist in
                    playlistCardView(for: playlist)
                        .frame(height: 180)
                        .onTapGesture {
                            DispatchQueue.main.async {
                                miniPlayerManager.musicPlayer.setQueue(with: playlist.items)
                                if let firstItem = playlist.items.first {
                                    miniPlayerManager.musicPlayer.play(at: playlist.items.firstIndex(of: firstItem) ?? 0)
                                    miniPlayerManager.maximizePlayer()
                                }
                            }
                        }
                }
            }
            .padding()
        }
        .onAppear {
            playlistFetcher.fetchPlaylists()
        }
    }

    /// Erstellt die Podcast-Ansicht
    /// - Parameters:
    ///   - podcastStore: Der PodcastStore zur Verwaltung der Podcasts
    ///   - podcastFetcher: Der PodcastFetcher zum Abrufen von Podcast-Daten
    ///   - showAddPodcastDialog: Binding für den Dialog zum Hinzufügen eines Podcasts
    /// - Returns: Eine View mit der Podcast-Ansicht
    static func podcastView(podcastStore: PodcastStore, podcastFetcher: PodcastFetcher, showAddPodcastDialog: Binding<Bool>) -> some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 40) {
                Button(action: { podcastStore.loadPodcasts() }) {
                    VStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        Text("Neuen Podcast hinzufügen")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .frame(height: 200)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                }
                
                if podcastStore.podcasts.isEmpty {
                    Text("Keine Podcasts gefunden.")
                } else {
                    ForEach(podcastStore.podcasts, id: \.id) { podcast in
                        NavigationLink(destination: PodcastDetailView(podcast: podcast, podcastFetcher: podcastFetcher)) {
                            podcastCardView(for: podcast)
                        }
                    }
                }
            }
            .padding()
        }
        .background(ScreenPainter.backgroundColor.edgesIgnoringSafeArea(.all))
        .onAppear {
            podcastStore.loadPodcasts()
        }
    }

    /// Erstellt die Radio-Ansicht
    /// - Parameters:
    ///   - radioFetcher: Der RadioFetcher zum Abrufen von Radiodaten
    ///   - showAddRadioDialog: Binding für den Dialog zum Hinzufügen eines Radiosenders
    ///   - currentRadio: Binding für den aktuell ausgewählten Radiosender
    ///   - currentRadioID: Binding für die ID des aktuell ausgewählten Radiosenders
    /// - Returns: Eine View mit der Radio-Ansicht
    static func radioView(radioFetcher: RadioFetcher, showAddRadioDialog: Binding<Bool>, currentRadio: Binding<Radio?>, currentRadioID: Binding<String?>) -> some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 40) {
                Button(action: { showAddRadioDialog.wrappedValue = true }) {
                    VStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        Text("Neuen Sender hinzufügen")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .frame(height: 200)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                }

                ForEach(radioFetcher.radios, id: \.id) { radio in
                    NavigationLink(
                        destination: RadioDetailView(radio: radio),
                        tag: radio.id,
                        selection: currentRadioID
                    ) {
                        radioCardView(for: radio)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            Task {
                await radioFetcher.fetchRadios()
            }
        }
    }

    // MARK: - Karten-Ansichten

    /// Erstellt eine Podcast-Karten-Ansicht
    /// - Parameter podcast: Der darzustellende Podcast
    /// - Returns: Eine View mit der Podcast-Karte
    /// Erstellt eine Podcast-Karten-Ansicht mit Bild-Handling
    static func podcastCardView(for podcast: PodcastFetcher.Podcast) -> some View {
        let podcastImage: UIImage? = {
            if let artworkPath = podcast.artworkFilePath,
               let imageData = try? Data(contentsOf: URL(fileURLWithPath: artworkPath)) {
                return UIImage(data: imageData)
            }
            return nil
        }()

        return mediaCardView(
            title: podcast.name,
            image: podcastImage,
            placeholder: "mic.fill",
            size: CGSize(width: 100, height: 100)
        )
    }

    /// Erstellt eine Radio-Karten-Ansicht
    /// - Parameter radio: Der darzustellende Radiosender
    /// - Returns: Eine View mit der Radio-Karte
    /// Erstellt eine Radio-Karten-Ansicht mit Bild-Handling
    static func radioCardView(for radio: Radio) -> some View {
        let radioImage: UIImage? = {
            if let artworkPath = radio.artworkFilePath,
               let imageData = try? Data(contentsOf: URL(fileURLWithPath: artworkPath)) {
                return UIImage(data: imageData)
            }
            return nil
        }()

        return mediaCardView(
            title: radio.name,
            image: radioImage,
            placeholder: "antenna.radiowaves.left.and.right",
            size: CGSize(width: 80, height: 80)
        )
    }

    // MARK: - Farbschema-Aktualisierung

    /// Aktualisiert die Primärfar

   
    
    
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

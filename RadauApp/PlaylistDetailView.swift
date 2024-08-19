import SwiftUI
import MediaPlayer

// Detailansicht für eine ausgewählte Playlist
struct PlaylistDetailView: View {
    let playlist: MPMediaPlaylist
    @ObservedObject var miniPlayerManager = ScreenPainter.miniPlayerManager
    @State private var isLandscape: Bool = UIDevice.current.orientation.isLandscape
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                VStack {
                    // Anzeige je nach Bildschirmorientierung: Landscape oder Portrait
                    if isLandscape {
                        SongListView(playlist: playlist, miniPlayerManager: miniPlayerManager, isLandscape: true)
                    } else {
                        SongGridView(playlist: playlist, miniPlayerManager: miniPlayerManager, geometry: geometry, isLandscape: false)
                    }
                }
                // Mini-Player am unteren Rand der Ansicht
                ScreenPainter.renderMiniPlayer()
            }
            .background(ScreenPainter.primaryColor.edgesIgnoringSafeArea(.all)) // Hintergrundfarbe anwenden
            .navigationBarTitle(playlist.name ?? "Playlist", displayMode: .inline) // Titel der Navigation Bar
            .toolbar {
                // Toolbar-Button zum Öffnen des Bildpickers
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showImagePicker = true
                    }) {
                        Image(systemName: "pencil")
                            .imageScale(.large)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .sheet(isPresented: $showImagePicker) {
                        PhotoPickerView(selectedImage: $selectedImage, playlistID: playlist.persistentID)
                            .onDisappear {
                                if let image = selectedImage {
                                    let screenPainter = ScreenPainter()
                                    screenPainter.updateImage(for: playlist, image: image)
                                }
                            }
                    }
                }
            }
            .onRotate { newOrientation in
                // Aktualisiere die Ausrichtung, aber ignoriere FaceUp und FaceDown
                if newOrientation.isLandscape {
                    isLandscape = true
                } else if newOrientation.isPortrait {
                    isLandscape = false
                }
            }
            // Zeigt den MusicPlayerView als modale Ansicht, wenn miniPlayerManager.showPlayer aktiviert ist
            .sheet(isPresented: $miniPlayerManager.showPlayer) {
                MusicPlayerView(musicPlayer: miniPlayerManager.musicPlayer, showMiniPlayer: $miniPlayerManager.showMiniPlayer)
            }
        }
    }
}

// Ansicht für die Playlist im List-Layout
struct SongListView: View {
    let playlist: MPMediaPlaylist
    @ObservedObject var miniPlayerManager: MiniPlayerManager
    var isLandscape: Bool // Zustand für die Orientierung

    var body: some View {
        List {
            // Zufallswiedergabe-Eintrag als erster Song
            HStack(spacing: 15) {
                Image(systemName: "shuffle")
                    .imageScale(.large)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(ScreenPainter.textColor)
                    .frame(width: 50, height: 50, alignment: .center)

                VStack(alignment: .leading) {
                    Text("Zufallswiedergabe")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(ScreenPainter.textColor)
                }
                Spacer()
            }
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity) // Zeile füllt die gesamte Breite aus
            .background(ScreenPainter.primaryColor)
            .listRowInsets(EdgeInsets()) // Entfernt unerwünschte Einrückungen
            .onTapGesture {
                shuffleAndPlay()
            }

            // Normale Songs in der Playlist
            ForEach(playlist.items, id: \.persistentID) { item in
                HStack(spacing: 15) {
                    ScreenPainter.artworkView(for: item.artwork, size: CGSize(width: 50, height: 50))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title ?? "Unbenannter Titel")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(ScreenPainter.textColor)
                        Text(item.artist ?? "Unbekannter Künstler")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 5)
                .background(ScreenPainter.primaryColor)
                .onTapGesture {
                    // Stoppen des Shuffle-Modus und Abspielen des ausgewählten Songs
                    miniPlayerManager.musicPlayer.stopShuffle()
                    miniPlayerManager.musicPlayer.setQueue(with: playlist.items)
                    miniPlayerManager.musicPlayer.play(at: playlist.items.firstIndex(of: item)!)
                    miniPlayerManager.maximizePlayer()
                }
            }
            .listRowBackground(ScreenPainter.primaryColor)
        }
        .listStyle(PlainListStyle())
        .background(ScreenPainter.primaryColor.edgesIgnoringSafeArea(.all))
    }
    
    // Funktion zum Shuffle und Abspielen der Songs
    private func shuffleAndPlay() {
        miniPlayerManager.musicPlayer.setQueue(with: playlist.items)
        miniPlayerManager.musicPlayer.playShuffledQueue()
        miniPlayerManager.maximizePlayer()
    }
}

// Ansicht für die Playlist im Grid-Layout
struct SongGridView: View {
    let playlist: MPMediaPlaylist
    @ObservedObject var miniPlayerManager: MiniPlayerManager
    let geometry: GeometryProxy
    var isLandscape: Bool // Zustand für die Orientierung
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 0) {
                // Shuffle-Option als erstes Element
                VStack {
                    Image(systemName: "shuffle")
                        .imageScale(.large)
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(ScreenPainter.textColor)
                    
                    if isLandscape {
                        Text("Zufallswiedergabe")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(ScreenPainter.textColor)
                    }
                }
                .padding()
                .background(ScreenPainter.primaryColor)
                .onTapGesture {
                    shuffleAndPlay()
                }

                // Normale Songs in der Playlist
                ForEach(playlist.items, id: \.persistentID) { item in
                    ScreenPainter.artworkView(for: item.artwork, size: CGSize(width: geometry.size.width / 2, height: geometry.size.width / 2))
                        .onTapGesture {
                            // Stoppen des Shuffle-Modus und Abspielen des ausgewählten Songs
                            miniPlayerManager.musicPlayer.stopShuffle()
                            miniPlayerManager.musicPlayer.setQueue(with: playlist.items)
                            miniPlayerManager.musicPlayer.play(at: playlist.items.firstIndex(of: item)!)
                            miniPlayerManager.maximizePlayer()
                        }
                }
            }
        }
        .background(ScreenPainter.primaryColor.edgesIgnoringSafeArea(.all))
    }
    
    // Funktion zum Shuffle und Abspielen der Songs
    private func shuffleAndPlay() {
        miniPlayerManager.musicPlayer.setQueue(with: playlist.items)
        miniPlayerManager.musicPlayer.playShuffledQueue()
        miniPlayerManager.maximizePlayer()
    }
}

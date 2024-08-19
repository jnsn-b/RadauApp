import SwiftUI
import MediaPlayer

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
                    if isLandscape {
                        SongListView(playlist: playlist, miniPlayerManager: miniPlayerManager, isLandscape: true)
                    } else {
                        SongGridView(playlist: playlist, miniPlayerManager: miniPlayerManager, geometry: geometry, isLandscape: false)
                    }
                }

                ScreenPainter.renderMiniPlayer()
            }
            .background(ScreenPainter.primaryColor.edgesIgnoringSafeArea(.all))
            .navigationBarTitle(playlist.name ?? "Playlist", displayMode: .inline)
            .toolbar {
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
                // Verhindere, dass "faceUp" oder "faceDown" als Landscape oder Portrait behandelt werden
                if newOrientation.isLandscape {
                    isLandscape = true
                } else if newOrientation.isPortrait {
                    isLandscape = false
                }
            }
            .sheet(isPresented: $miniPlayerManager.showPlayer) {
                MusicPlayerView(musicPlayer: miniPlayerManager.musicPlayer, showMiniPlayer: $miniPlayerManager.showMiniPlayer)
            }
        }
    }
}

struct SongListView: View {
    let playlist: MPMediaPlaylist
    @ObservedObject var miniPlayerManager: MiniPlayerManager
    var isLandscape: Bool // Zustand für die Orientierung

    var body: some View {
        List {
            // Zufallswiedergabe-Eintrag als erster Song
            HStack(spacing: 15) { // Einstellung des Abstands zwischen dem Logo und dem Text
                Image(systemName: "shuffle")
                    .imageScale(.large)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(ScreenPainter.textColor)
                    .frame(width: 50, height: 50, alignment: .center) // Gleiche Größe und Ausrichtung wie das Coverbild

                VStack(alignment: .leading) {
                    Text("Zufallswiedergabe")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(ScreenPainter.textColor)
                }
                Spacer() // Sicherstellen, dass der gesamte Raum ausgefüllt wird
            }
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity) // Zeile füllt die gesamte Breite aus
            .background(ScreenPainter.primaryColor)
            .listRowInsets(EdgeInsets()) // Entfernt unerwünschte Einrückungen
            .onTapGesture {
                shuffleAndPlay()
            }

            // Normale Songs
            ForEach(playlist.items, id: \.persistentID) { item in
                HStack(spacing: 15) { // Gleicher Abstand wie beim Shuffle-Eintrag
                    ScreenPainter.artworkView(for: item.artwork, size: CGSize(width: 50, height: 50))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title ?? "Unbenannter Titel")
                            .font(.system(size: 20, weight: .bold))  // Größere Schrift für den Titel
                            .foregroundColor(ScreenPainter.textColor)
                        Text(item.artist ?? "Unbekannter Künstler")
                            .font(.system(size: 16))  // Größere Schrift für den Künstler
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 5)
                .background(ScreenPainter.primaryColor)  // Primary Color für Listenelemente
                .onTapGesture {
                    miniPlayerManager.musicPlayer.stopShuffle() // Hier stoppen wir den Shuffle-Modus
                    miniPlayerManager.musicPlayer.setQueue(with: playlist.items)
                    miniPlayerManager.musicPlayer.play(at: playlist.items.firstIndex(of: item)!)
                    miniPlayerManager.maximizePlayer()
                }
            }
            .listRowBackground(ScreenPainter.primaryColor) // Primary Color für die Zeilen
        }
        .listStyle(PlainListStyle())
        .background(ScreenPainter.primaryColor.edgesIgnoringSafeArea(.all)) // Primary Color für die gesamte List
    }
    
    private func shuffleAndPlay() {
        miniPlayerManager.musicPlayer.setQueue(with: playlist.items)
        miniPlayerManager.musicPlayer.playShuffledQueue()
        miniPlayerManager.maximizePlayer()
    }
}

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

                // Normale Songs
                ForEach(playlist.items, id: \.persistentID) { item in
                    ScreenPainter.artworkView(for: item.artwork, size: CGSize(width: geometry.size.width / 2, height: geometry.size.width / 2))
                        .onTapGesture {
                            miniPlayerManager.musicPlayer.stopShuffle() // Hier stoppen wir den Shuffle-Modus
                            miniPlayerManager.musicPlayer.setQueue(with: playlist.items)
                            miniPlayerManager.musicPlayer.play(at: playlist.items.firstIndex(of: item)!)
                            miniPlayerManager.maximizePlayer()
                        }
                }
            }
        }
        .background(ScreenPainter.primaryColor.edgesIgnoringSafeArea(.all)) // Primary Color für die ScrollView
    }
    
    private func shuffleAndPlay() {
        miniPlayerManager.musicPlayer.setQueue(with: playlist.items)
        miniPlayerManager.musicPlayer.playShuffledQueue()
        miniPlayerManager.maximizePlayer()
    }
}

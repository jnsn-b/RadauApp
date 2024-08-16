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
                        SongListView(playlist: playlist, miniPlayerManager: miniPlayerManager)
                    } else {
                        SongGridView(playlist: playlist, miniPlayerManager: miniPlayerManager, geometry: geometry)
                    }
                }
                
                ScreenPainter.renderMiniPlayer()
            }
            .background(ScreenPainter.primaryColor.edgesIgnoringSafeArea(.all))  // Primary Color für den gesamten ZStack
            .navigationBarTitle(playlist.name ?? "Playlist", displayMode: .inline)
            .toolbar {
                // Hinzufügen des Stift-Symbols rechts oben, um ein Bild auszuwählen
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showImagePicker = true
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.white)  // Setzt die Farbe des Stift-Symbols auf Weiß
                    }
                    .sheet(isPresented: $showImagePicker) {
                        PhotoPickerView(selectedImage: $selectedImage)
                            .onDisappear {
                                if let image = selectedImage {
                                    let screenPainter = ScreenPainter()
                                    screenPainter.updateImage(for: playlist, image: image)
                                }
                            }
                    }
                }
            }
            .onAppear {
                updateOrientation(geometry: geometry)
            }
            .onChange(of: geometry.size) { _ in
                updateOrientation(geometry: geometry)
            }
            .sheet(isPresented: $miniPlayerManager.showPlayer) {
                MusicPlayerView(musicPlayer: miniPlayerManager.musicPlayer, showMiniPlayer: $miniPlayerManager.showMiniPlayer)
            }
        }
    }
    
    private func updateOrientation(geometry: GeometryProxy) {
        isLandscape = geometry.size.width > geometry.size.height
    }
}

struct SongListView: View {
    let playlist: MPMediaPlaylist
    @ObservedObject var miniPlayerManager: MiniPlayerManager
    
    var body: some View {
        List {
            ForEach(playlist.items, id: \.persistentID) { item in
                HStack {
                    ScreenPainter.artworkView(for: item.artwork, size: CGSize(width: 50, height: 50))
                    
                    VStack(alignment: .leading) {
                        Text(item.title ?? "Unbenannter Titel")
                            .font(ScreenPainter.titleFont)
                            .foregroundColor(ScreenPainter.textColor)
                        Text(item.artist ?? "Unbekannter Künstler")
                            .font(ScreenPainter.bodyFont)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 5)
                .background(ScreenPainter.primaryColor)  // Primary Color für Listenelemente
                .cornerRadius(10)
                .onTapGesture {
                    miniPlayerManager.musicPlayer.setQueue(with: playlist.items)
                    if let index = playlist.items.firstIndex(of: item) {
                        miniPlayerManager.musicPlayer.play(at: index)
                    }
                    miniPlayerManager.maximizePlayer()
                }
            }
            .listRowBackground(ScreenPainter.primaryColor) // Primary Color für die Zeilen
        }
        .listStyle(PlainListStyle())
        .background(ScreenPainter.primaryColor.edgesIgnoringSafeArea(.all)) // Primary Color für die gesamte List
    }
}

struct SongGridView: View {
    let playlist: MPMediaPlaylist
    @ObservedObject var miniPlayerManager: MiniPlayerManager
    let geometry: GeometryProxy
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 0) {
                ForEach(playlist.items, id: \.persistentID) { item in
                    ScreenPainter.artworkView(for: item.artwork, size: CGSize(width: geometry.size.width / 2, height: geometry.size.width / 2))
                        .onTapGesture {
                            miniPlayerManager.musicPlayer.setQueue(with: playlist.items)
                            if let index = playlist.items.firstIndex(of: item) {
                                miniPlayerManager.musicPlayer.play(at: index)
                            }
                            miniPlayerManager.maximizePlayer()
                        }
                }
            }
        }
        .background(ScreenPainter.primaryColor.edgesIgnoringSafeArea(.all)) // Primary Color für die ScrollView
    }
}

import SwiftUI
import MediaPlayer

// Detailansicht für eine ausgewählte Playlist
struct PlaylistDetailView: View {
    let playlist: MPMediaPlaylist
    @EnvironmentObject var audioPlayer: AudioPlayer
    @EnvironmentObject var playerUI: PlayerUIState
    @State private var isLandscape: Bool = UIDevice.current.orientation.isLandscape
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?

    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                VStack {
                    // Anzeige je nach Bildschirmorientierung: Landscape oder Portrait
                    if isLandscape {
                        SongListView(playlist: playlist, audioPlayer: _audioPlayer, isLandscape: true)
                    } else {
                        SongGridView(playlist: playlist, audioPlayer: _audioPlayer, geometry: geometry, isLandscape: false)
                    }
                }
 
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
                                    let screenPainter = ScreenPainter.shared
                                    screenPainter.updateImage(for: playlist, image: image)
                                }
                            }
                    }
                }
            }
            .onRotate { newOrientation in
                if newOrientation.isLandscape {
                    isLandscape = true
                } else if newOrientation.isPortrait {
                    isLandscape = false
                }
            }
        }
    }
    
    
    // ✅ `SongListView` mit `AudioPlayer`
    struct SongListView: View {
        let playlist: MPMediaPlaylist
        @EnvironmentObject var audioPlayer: AudioPlayer
        @EnvironmentObject var playerUI: PlayerUIState
        var isLandscape: Bool
        
        var body: some View {
            List
            {
                
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
               
                .onTapGesture {
                    shuffleAndPlay()
                }
                
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
                    .background(ScreenPainter.primaryColor)
                           .listRowBackground(ScreenPainter.primaryColor)
                    .onTapGesture {
                        audioPlayer.switchPlayer(toAppleMusic: true)
                        audioPlayer.setQueue(with: playlist.items)
                        audioPlayer.play(at: playlist.items.firstIndex(of: item)!)
                        playerUI.showPlayer = true
                        playerUI.showMiniPlayer = false
                    }
                }

            }
            
            .listStyle(PlainListStyle()) // ✅ Setzt den List-Stil korrekt
            .background(ScreenPainter.primaryColor.edgesIgnoringSafeArea(.all)) // ✅ Hintergrund richtig setzen
               .onAppear {
                   UITableView.appearance().backgroundColor = UIColor(ScreenPainter.primaryColor) // ✅ Hintergrund für gesamte `List` setzen
               }
        }
        
        private func shuffleAndPlay() {
            audioPlayer.setQueue(with: playlist.items)
            audioPlayer.playShuffledQueue()
            playerUI.showPlayer = true
            playerUI.showMiniPlayer = false
        }
    }
    
    // ✅ `SongGridView` mit `AudioPlayer`
    struct SongGridView: View {
        let playlist: MPMediaPlaylist
        @EnvironmentObject var audioPlayer: AudioPlayer
        @EnvironmentObject var playerUI: PlayerUIState
        let geometry: GeometryProxy
        var isLandscape: Bool
        
        var body: some View {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 0) {
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
                    .background(ScreenPainter.primaryColor)
                    .onTapGesture {
                        shuffleAndPlay()
                    }
                    
                    ForEach(playlist.items, id: \.persistentID) { item in
                        ScreenPainter.artworkView(for: item.artwork, size: CGSize(width: geometry.size.width / 2, height: geometry.size.width / 2))

                            
                            .onTapGesture {
                                audioPlayer.switchPlayer(toAppleMusic: true)
                                audioPlayer.setQueue(with: playlist.items)
                                audioPlayer.play(at: playlist.items.firstIndex(of: item)!)
                                playerUI.showPlayer = true
                                playerUI.showMiniPlayer = false
                               
                                
                            }
                    }
                  
                    
                }

                
                
            }
        }
        
        private func shuffleAndPlay() {
            audioPlayer.switchPlayer(toAppleMusic: true)
            audioPlayer.setQueue(with: playlist.items)
            audioPlayer.playShuffledQueue()
            playerUI.showPlayer = true
            playerUI.showMiniPlayer = false
        }
    }
}

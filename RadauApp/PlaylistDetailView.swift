import SwiftUI
import MediaPlayer

struct PlaylistDetailView: View {
    let playlist: MPMediaPlaylist
    @ObservedObject var miniPlayerManager = ScreenPainter.miniPlayerManager
    @State private var isLandscape: Bool = UIDevice.current.orientation.isLandscape

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                VStack {
                    if isLandscape {
                        List {
                            ForEach(playlist.items, id: \.persistentID) { item in
                                HStack {
                                    ScreenPainter.artworkView(for: item.artwork, size: CGSize(width: 50, height: 50))
                                    
                                    VStack(alignment: .leading) {
                                        Text(item.title ?? "Unbenannter Titel")
                                            .font(.headline)
                                        Text(item.artist ?? "Unbekannter Künstler")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.vertical, 5)
                                .onTapGesture {
                                    miniPlayerManager.musicPlayer.setQueue(with: playlist.items)
                                    if let index = playlist.items.firstIndex(of: item) {
                                        miniPlayerManager.musicPlayer.play(at: index)
                                    }
                                    miniPlayerManager.maximizePlayer()
                                }
                            }
                        }
                    } else {
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
                    }
                }
                
                ScreenPainter.renderMiniPlayer()
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

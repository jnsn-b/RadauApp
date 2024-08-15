import SwiftUI
import MediaPlayer

struct MusicPlayerView: View {
    @ObservedObject var musicPlayer: MusicPlayer
    @Binding var showMiniPlayer: Bool
    @State private var isLandscape: Bool = UIDevice.current.orientation.isLandscape

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                if isLandscape {
                    HStack {
                        ScreenPainter.artworkView(for: musicPlayer.currentSong?.artwork, size: CGSize(width: 300, height: 300))
                        
                        VStack {
                            songInfoView
                            controlsView
                        }
                        .frame(width: geometry.size.width / 2)
                    }
                } else {
                    ScreenPainter.artworkView(for: musicPlayer.currentSong?.artwork, size: CGSize(width: 300, height: 300))
                    songInfoView
                    controlsView
                }
                
                Spacer()
            }
            .padding()
            .onAppear {
                updateOrientation(geometry: geometry)
                showMiniPlayer = false
            }
            .onDisappear {
                showMiniPlayer = true
            }
            .onChange(of: geometry.size) { _ in
                updateOrientation(geometry: geometry)
            }
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        if value.translation.height > 50 && !isLandscape {
                            ScreenPainter.miniPlayerManager.minimizePlayer()
                        }
                    }
            )
        }
    }
    
    private var songInfoView: some View {
        VStack {
            Text(musicPlayer.currentSong?.title ?? "Unbenannter Titel")
                .font(.headline)
                .padding(.top, 20)
            
            Text(musicPlayer.currentSong?.artist ?? "Unbekannter Künstler")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.bottom, 20)
        }
    }
    
    private var controlsView: some View {
        HStack {
            Button(action: {
                musicPlayer.previous()
            }) {
                Image(systemName: "backward.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
            }
            
            Spacer()
            
            Button(action: {
                if musicPlayer.isPlaying {
                    musicPlayer.pause()
                } else {
                    musicPlayer.play()
                }
            }) {
                Image(systemName: musicPlayer.isPlaying ? "pause.fill" : "play.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
            }
            
            Spacer()
            
            Button(action: {
                musicPlayer.next()
            }) {
                Image(systemName: "forward.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
            }
        }
        .padding(.horizontal, 40)
        .padding(.top, 30)
    }
    
    private func updateOrientation(geometry: GeometryProxy) {
        isLandscape = geometry.size.width > geometry.size.height
    }
}

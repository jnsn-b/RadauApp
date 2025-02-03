import SwiftUI

import SwiftUI

struct PlayerView: View {
    @EnvironmentObject var audioPlayer: AudioPlayer
    @EnvironmentObject var playerUI: PlayerUIState
    @State private var dragOffset: CGFloat = 0
    @State private var isLandscape: Bool = UIDevice.current.orientation.isLandscape
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if playerUI.showMiniPlayer {
                    miniPlayerView()
                        .onTapGesture {
                            withAnimation(.spring()) {
                                playerUI.showPlayer = true
                                playerUI.showMiniPlayer = false
                                
                            }
                            
                        }
                }
                
                if playerUI.showPlayer {
                    VStack {
                        Spacer()
                        
                            fullPlayerView(geometry: geometry)
                                .frame(maxWidth: .infinity)
                                .background(ScreenPainter.primaryColor.edgesIgnoringSafeArea(.all))
                                .transition(.move(edge: .bottom))
                                .zIndex(2)
                                .offset(y: dragOffset)
                                .onAppear {
                                    withAnimation(.easeInOut) {
                                        playerUI.showMiniPlayer = false
                                    }
                                    updateOrientation(geometry: geometry)
                                }
                                .onChange(of: geometry.size) { _ in
                                    updateOrientation(geometry: geometry)
                                    
                                    
                                }
                                .gesture(
                                    DragGesture()
                                        .onChanged { gesture in
                                            if gesture.translation.height > 0 {
                                                dragOffset = gesture.translation.height
                                            }
                                        }
                                        .onEnded { gesture in
                                            if gesture.translation.height > 100 {
                                                withAnimation(.spring()) {
                                                    playerUI.showPlayer = false
                                                    playerUI.showMiniPlayer = true // ✅ MiniPlayer zurückholen, wenn FullPlayer schließt
                                                    dragOffset = 0
                                                    
                                                }
                                            } else {
                                                withAnimation {
                                                    dragOffset = 0
                                                }
                                            }
                                        }
                                )
                       
                    }
                }
            }
            .animation(.easeInOut, value: playerUI.showPlayer)
        }
    }
        private func updateOrientation(geometry: GeometryProxy) {
            DispatchQueue.main.async {
                self.isLandscape = geometry.size.width > geometry.size.height
            }
        }
        
        // 📌 🎵 **FullPlayer jetzt als echtes Popup**
    private func fullPlayerView(geometry: GeometryProxy) -> some View {
        if isLandscape {
            return AnyView(landscapePlayerView()) // ✅ `geometry` entfernt
        } else {
            return AnyView(portraitPlayerView()) // ✅ `geometry` entfernt
        }
    }
        
        private func landscapePlayerView() -> some View {
            HStack {
                artworkView(size: CGSize(width: 200, height: 200))
                    .padding(.leading, 20)
                
                VStack {
                    if audioPlayer.isShuffleEnabled {
                               Image(systemName: "shuffle")
                                   .foregroundColor(.gray)
                                   .font(.title2)
                                   .padding(.top, 5)
                                   .transition(.opacity)
                                   .animation(.easeInOut, value: audioPlayer.isShuffleEnabled)
                           }
                    songInfoView
                    controlsView
                }
                .frame(maxWidth: .infinity)
                .padding(.trailing, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ScreenPainter.primaryColor.edgesIgnoringSafeArea(.all))
            .cornerRadius(15)
        }
        
        private func portraitPlayerView() -> some View {
            VStack {
                Spacer()
                artworkView(size: CGSize(width: 300, height: 300))
                    .frame(maxWidth: .infinity, alignment: .center)
                if audioPlayer.isShuffleEnabled {
                           Image(systemName: "shuffle")
                               .foregroundColor(.gray)
                               .font(.title2)
                               .padding(.top, 5)
                               .transition(.opacity)
                               .animation(.easeInOut, value: audioPlayer.isShuffleEnabled)
                       }
                
                songInfoView
                controlsView
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ScreenPainter.primaryColor.edgesIgnoringSafeArea(.all))
            .cornerRadius(15)
        }
        
        // 📌 🎶 **Mini-Player Ansicht**
    private func miniPlayerView() -> some View {
        VStack(spacing: 0) {
            HStack {
                artworkView(size: CGSize(width: 60, height: 60)) // ✅ Artwork etwas größer für bessere Sichtbarkeit
                VStack(alignment: .leading) {
                    Text(audioPlayer.currentTitle)
                        .font(ScreenPainter.bodyFont)
                        .foregroundColor(ScreenPainter.textColor)
                        .lineLimit(1)
                    Text(audioPlayer.currentSource)
                        .font(ScreenPainter.bodyFont)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                Spacer()
                Button(action: {
                    if audioPlayer.isPlaying {
                        audioPlayer.pause()
                    } else {
                        audioPlayer.play()
                    }
                }) {
                    Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                        .resizable()
                        .frame(width: 35, height: 35) // ✅ Buttons leicht vergrößert
                        .foregroundColor(ScreenPainter.secondaryColor)
                }
                if !audioPlayer.isRadioMode {
                    Button(action: {
                        audioPlayer.next()
                    }) {
                        Image(systemName: "forward.fill")
                            .resizable()
                            .frame(width: 35, height: 35)
                            .foregroundColor(ScreenPainter.secondaryColor)
                    }
                }
            }
            .padding()
            .background(ScreenPainter.primaryColor.edgesIgnoringSafeArea(.bottom))
            .shadow(color: .gray.opacity(0.4), radius: 5, x: 0, y: 2)
            .frame(maxWidth: .infinity)
            .frame(height: max(60, min(UIScreen.main.bounds.height * 0.12, 100)))
            .onTapGesture {
                withAnimation(.spring()) {
                    playerUI.showPlayer = true
                    playerUI.showMiniPlayer = false
                    
                }
            }
            .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                if gesture.translation.height < 0 { // ✅ Nach oben ziehen erkannt
                                    dragOffset = gesture.translation.height
                                }
                            }
                            .onEnded { gesture in
                                if gesture.translation.height < -50 { // ✅ Threshold für Hochziehen
                                    withAnimation(.spring()) {
                                        playerUI.showPlayer = true
                                        playerUI.showMiniPlayer = false
                                        dragOffset = 0
                                    }
                                } else {
                                    withAnimation {
                                        dragOffset = 0 // Falls nicht stark genug gezogen, bleibt er klein
                                    }
                                }
                            }
                    )
            
    
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        
        // 📌 🎵 **Artwork**
        private func artworkView(size: CGSize) -> some View {
            Group {
                if let artwork = audioPlayer.artwork {
                    Image(uiImage: audioPlayer.artwork ?? UIImage())
                        .resizable()
                        .scaledToFit()
                        .frame(width: size.width, height: size.height)
                        .cornerRadius(10)
                        .id(UUID())
                } else {
                    Image(systemName: "music.note")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size.width, height: size.height)
                        .foregroundColor(.gray)
                        .id(UUID())
                }
            }
        }
        
        // 📌 ℹ️ **Song-Info**
        private var songInfoView: some View {
            VStack {
                Text(audioPlayer.currentTitle)
                    .font(.title)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                Text(audioPlayer.currentSource)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
        }
        
        // 📌 🎛 **Steuerung**
    private var controlsView: some View {
        HStack {
            if audioPlayer.isRadioMode {
                // 📻 Nur Play/Stop für Radio
                Button(action: {
                    if audioPlayer.isPlaying {
                        audioPlayer.pause()
                    } else {
                        audioPlayer.play()
                    }
                }) {
                    Image(systemName: audioPlayer.isPlaying ? "stop.fill" : "play.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(ScreenPainter.secondaryColor)
                }
            } else {
                // 🎵 Musik & Podcast haben Zurück / Play / Weiter
                Button(action: {
                    if audioPlayer.isPodcastMode {
                        audioPlayer.previousPodcastEpisode(episodes: audioPlayer.currentPodcast?.episodes ?? [])
                    } else {
                        audioPlayer.previous()
                    }
                }) {
                    Image(systemName: "backward.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(ScreenPainter.secondaryColor)
                }
                Spacer()
                Button(action: {
                    if audioPlayer.isPlaying {
                        audioPlayer.pause()
                    } else {
                        audioPlayer.play()
                    }
                }) {
                    Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(ScreenPainter.secondaryColor)
                }
                Spacer()
                Button(action: {
                    if audioPlayer.isPodcastMode {
                        audioPlayer.nextPodcastEpisode(episodes: audioPlayer.currentPodcast?.episodes ?? [])
                    } else {
                        audioPlayer.next()
                    }
                }) {
                    Image(systemName: "forward.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(ScreenPainter.secondaryColor)
                }
            }
        }
        .padding(.horizontal, 40)
        .padding(.top, 30)
    }
    }
 
class PlayerUIState: ObservableObject {
    @Published var showPlayer: Bool = false
    @Published var showMiniPlayer: Bool = true
}

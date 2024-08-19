import SwiftUI

struct MusicPlayerView: View {
    @ObservedObject var musicPlayer: MusicPlayer
    @Binding var showMiniPlayer: Bool
    @State private var isLandscape: Bool = UIDevice.current.orientation.isLandscape

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()

                if isLandscape {
                    // Layout für Landscape-Ansicht
                    HStack {
                        ScreenPainter.artworkView(for: musicPlayer.currentSong?.artwork, size: CGSize(width: 300, height: 300))

                        VStack {
                            songInfoView
                            controlsView
                        }
                        .frame(width: geometry.size.width / 2)
                    }
                } else {
                    // Layout für Portrait-Ansicht
                    ScreenPainter.artworkView(for: musicPlayer.currentSong?.artwork, size: CGSize(width: 300, height: 300))
                    songInfoView
                    controlsView  // Die Steuerungselemente bleiben direkt unter dem Song-Info-Bereich
                }

                Spacer()
            }
            .padding()
            .background(ScreenPainter.primaryColor.edgesIgnoringSafeArea(.all))  // Hintergrundfarbe anwenden
            .onAppear {
                updateOrientation(geometry: geometry)
                showMiniPlayer = false  // Verberge den Mini-Player, wenn der Hauptplayer erscheint
            }
            .onDisappear {
                showMiniPlayer = true  // Zeige den Mini-Player wieder an, wenn der Hauptplayer verschwindet
            }
            .onChange(of: geometry.size) { _ in
                updateOrientation(geometry: geometry)
            }
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        if isLandscape {
                            // Swipen nach unten oder zur Seite im Landscape-Modus
                            if abs(value.translation.width) > 100 || value.translation.height > 50 {
                                ScreenPainter.miniPlayerManager.minimizePlayer()
                            }
                        } else {
                            // Swipen nach unten im Portrait-Modus
                            if value.translation.height > 50 {
                                ScreenPainter.miniPlayerManager.minimizePlayer()
                            }
                        }
                    }
            )
        }
    }

    private var songInfoView: some View {
        VStack(spacing: 5) {  // Der vertikale Abstand zwischen den Elementen wurde reduziert
            // Anzeige des Songtitels
            Text(musicPlayer.currentSong?.title ?? "Unbenannter Titel")
                .font(ScreenPainter.titleFont)
                .foregroundColor(ScreenPainter.textColor)
                .padding(.top, 20)

            // Anzeige des Interpreten
            Text(musicPlayer.currentSong?.artist ?? "Unbekannter Künstler")
                .font(ScreenPainter.bodyFont)
                .foregroundColor(.gray)

            // Anzeige des Shuffle-Symbols, wenn Shuffle aktiviert ist
            if musicPlayer.isShuffleEnabled {
                Image(systemName: "shuffle")
                    .foregroundColor(.gray)  // Leicht ausgegrautes Shuffle-Symbol
                    .padding(.top, 5)  // Der Abstand zum vorherigen Text wurde minimiert
            }
        }
    }

    private var controlsView: some View {
        HStack {
            // Button für vorherigen Song
            Button(action: {
                musicPlayer.previous()
            }) {
                Image(systemName: "backward.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(ScreenPainter.secondaryColor)
            }

            Spacer()

            // Button zum Abspielen/Pausieren
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
                    .foregroundColor(ScreenPainter.secondaryColor)
            }

            Spacer()

            // Button für nächsten Song
            Button(action: {
                musicPlayer.next()
            }) {
                Image(systemName: "forward.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(ScreenPainter.secondaryColor)
            }
        }
        .padding(.horizontal, 40)
        .padding(.top, 30)  // Die Steuerungselemente bleiben direkt unterhalb des songInfoView, ohne zusätzlichen Abstand
    }

    // Funktion zum Aktualisieren der Ausrichtung basierend auf den Geometriegrößen
    private func updateOrientation(geometry: GeometryProxy) {
        isLandscape = geometry.size.width > geometry.size.height
    }
}

import SwiftUI

struct MiniPlayerView: View {
    @ObservedObject var musicPlayer: MusicPlayer
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()  // Platz für darüberliegenden Inhalt

            HStack {
                // Zeigt das Album-Cover oder ein Standardbild an, falls kein Artwork verfügbar ist
                ScreenPainter.artworkView(for: musicPlayer.currentSong?.artwork, size: CGSize(width: 50, height: 50))
                
                // Anzeige des Songtitels und des Interpreten
                VStack(alignment: .leading) {
                    Text(musicPlayer.currentSong?.title ?? "Unbenannter Titel")
                        .font(ScreenPainter.titleFont)
                        .foregroundColor(ScreenPainter.textColor)
                        .lineLimit(1)  // Begrenze die Zeile auf eine Zeile, um Überlauf zu vermeiden
                    
                    Text(musicPlayer.currentSong?.artist ?? "Unbekannter Künstler")
                        .font(ScreenPainter.bodyFont)
                        .foregroundColor(.gray)
                        .lineLimit(1)  // Begrenze die Zeile auf eine Zeile, um Überlauf zu vermeiden
                }
                
                Spacer()  // Fügt Platz zwischen dem Text und den Steuerelementen ein
                
                // Button zum Abspielen oder Pausieren des aktuellen Songs
                Button(action: {
                    if musicPlayer.isPlaying {
                        musicPlayer.pause()
                    } else {
                        musicPlayer.play()
                    }
                }) {
                    Image(systemName: musicPlayer.isPlaying ? "pause.fill" : "play.fill")
                        .resizable()
                        .frame(width: 30, height: 30)  // Größe des Icons
                        .foregroundColor(ScreenPainter.secondaryColor)  // Setzt die Farbe des Icons
                }
                
                // Button zum Überspringen zum nächsten Song
                Button(action: {
                    musicPlayer.next()
                }) {
                    Image(systemName: "forward.fill")
                        .resizable()
                        .frame(width: 30, height: 30)  // Größe des Icons
                        .foregroundColor(ScreenPainter.secondaryColor)  // Setzt die Farbe des Icons
                }
            }
            .padding()
            .background(ScreenPainter.primaryColor.edgesIgnoringSafeArea(.bottom))  // Hintergrundfarbe und Sicherstellen, dass sie unten das Safe Area ignoriert
            .shadow(color: .gray, radius: 5, x: 0, y: 2)  // Fügt einen Schatten hinzu, um den Mini-Player abzuheben
            .frame(height: 60)  // Höhe des MiniPlayers festlegen
        }
    }
}

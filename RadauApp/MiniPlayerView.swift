import SwiftUI
import MediaPlayer

struct MiniPlayerView: View {
    @ObservedObject var musicPlayer: MusicPlayer
    
    var body: some View {
        HStack {
            ScreenPainter.artworkView(for: musicPlayer.currentSong?.artwork, size: CGSize(width: 50, height: 50))
            
            VStack(alignment: .leading) {
                Text(musicPlayer.currentSong?.title ?? "Unbenannter Titel")
                    .font(ScreenPainter.titleFont)
                    .foregroundColor(ScreenPainter.textColor)
                    .lineLimit(1)
                
                Text(musicPlayer.currentSong?.artist ?? "Unbekannter Künstler")
                    .font(ScreenPainter.bodyFont)
                    .foregroundColor(.gray)
                    .lineLimit(1)
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
                    .frame(width: 30, height: 30)
                    .foregroundColor(ScreenPainter.secondaryColor)  // Nur die Vordergrundfarbe
            }
            
            Button(action: {
                musicPlayer.next()
            }) {
                Image(systemName: "forward.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(ScreenPainter.secondaryColor)  // Nur die Vordergrundfarbe
            }
        }
        .padding()
        .background(ScreenPainter.primaryColor.edgesIgnoringSafeArea(.all))  // Primary Color als Hintergrund
        .cornerRadius(10)
        .shadow(color: .gray, radius: 5, x: 0, y: 2)
    }
}

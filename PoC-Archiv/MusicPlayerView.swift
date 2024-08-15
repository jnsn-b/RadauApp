import SwiftUI
import MusicKit

struct MusicPlayerView: View {
    @ObservedObject var playerManager: MusicPlayerManager

    var body: some View {
        VStack {
            if let artworkURL = playerManager.currentSong?.artwork?.url(width: 300, height: 300) {
                AsyncImage(url: artworkURL) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                        .cornerRadius(15)
                } placeholder: {
                    Image(systemName: "music.note")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                        .cornerRadius(15)
                }
            } else {
                Image(systemName: "music.note")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                    .cornerRadius(15)
            }

            Text(playerManager.currentSong?.title ?? "Unbekannter Titel")
                .font(.title)
                .padding(.top)
            Text(playerManager.currentSong?.artistName ?? "Unbekannter Künstler")
                .font(.subheadline)

            HStack {
                Button(action: {
                    playerManager.previous()
                }) {
                    Image(systemName: "backward.fill")
                        .font(.largeTitle)
                }
                .padding()

                Button(action: {
                    // Play/Pause button logic
                    if playerManager.isPlaying {
                        playerManager.pause()
                    } else {
                        if let currentSong = playerManager.currentSong {
                            playerManager.play(song: currentSong)
                        }
                    }
                }) {
                    Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.largeTitle)
                }
                .padding()

                Button(action: {
                    playerManager.next()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.largeTitle)
                }
                .padding()
            }
        }
        .padding()
    }
}

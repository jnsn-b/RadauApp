import Foundation
import MusicKit

class MusicPlayerManager: ObservableObject {
    @Published var musicPlayer: ApplicationMusicPlayer = ApplicationMusicPlayer.shared
    @Published var currentSong: Song?
    @Published var isPlaying = false

    func play(song: Song) {
        Task {
            do {
                try await musicPlayer.queue = [song]
                try await musicPlayer.play()
                currentSong = song
                isPlaying = true
            } catch {
                print("Failed to play song: \(error.localizedDescription)")
            }
        }
    }

    func pause() {
        Task {
            await musicPlayer.pause()
            isPlaying = false
        }
    }

    func next() {
        Task {
            //await musicPlayer.advanceToNextEntry()
            await musicPlayer.skipToNextEntry
        }
    }

    func previous() {
        Task {
            //await musicPlayer.skipToPreviousEntry()
            await musicPlayer.skipToPreviousEntry
        }
    }
}

import Foundation
import MediaPlayer
import AVFoundation

class AudioPlayer: ObservableObject, AudioPlayerProtocol {
    private var appleMusicPlayer: MPMusicPlayerController?
    private var avPlayer: AVPlayer?
    private var isUsingAppleMusic = false

    init(useAppleMusic: Bool = false) {
        self.isUsingAppleMusic = useAppleMusic
        if useAppleMusic {
            appleMusicPlayer = MPMusicPlayerController.applicationMusicPlayer
        } else {
            avPlayer = AVPlayer()
        }
    }

    func load(url: URL?) {
        guard let url = url, !isUsingAppleMusic else { return }
        avPlayer = AVPlayer(url: url)
    }

    func play() {
        if isUsingAppleMusic {
            appleMusicPlayer?.play()
        } else {
            avPlayer?.play()
        }
    }

    func pause() {
        if isUsingAppleMusic {
            appleMusicPlayer?.pause()
        } else {
            avPlayer?.pause()
        }
    }

    func stop() {
        if isUsingAppleMusic {
            appleMusicPlayer?.stop()
        } else {
            avPlayer?.pause()
            avPlayer?.seek(to: .zero)
        }
    }

    func next() {
        if isUsingAppleMusic {
            appleMusicPlayer?.skipToNextItem()
        } else {
            // Implementiere eine Playlist-Logik für AVPlayer
        }
    }

    func previous() {
        if isUsingAppleMusic {
            appleMusicPlayer?.skipToPreviousItem()
        } else {
            // Implementiere eine Playlist-Logik für AVPlayer
        }
    }

    func switchPlayer(toAppleMusic: Bool) {
        if toAppleMusic {
            appleMusicPlayer = MPMusicPlayerController.applicationMusicPlayer
            avPlayer = nil
        } else {
            avPlayer = AVPlayer()
            appleMusicPlayer = nil
        }
        isUsingAppleMusic = toAppleMusic
    }
}

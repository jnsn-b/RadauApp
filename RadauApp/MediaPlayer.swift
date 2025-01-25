import Foundation
import MediaPlayer
 


class MediaPlayer: ObservableObject {
    private var musicPlayer: MPMusicPlayerController
    private var avPlayer: AVPlayer?
    @Published var isPlaying = false
    @Published var currentItem: MediaItem?
    
    struct MediaItem {
        let id: String
        let title: String
        let artist: String
        let artwork: UIImage?
        let isMusic: Bool
        let url: URL?
    }
    
    private var items: [MediaItem] = []
    var isShuffleEnabled = false

    init() {
        musicPlayer = MPMusicPlayerController.applicationMusicPlayer
        setupNotifications()
        musicPlayer.beginGeneratingPlaybackNotifications()
        updateItemInfo()
        updatePlaybackState()
    }

    deinit {
        musicPlayer.endGeneratingPlaybackNotifications()
        NotificationCenter.default.removeObserver(self)
    }

    func play() {
        if currentItem?.isMusic == true {
            musicPlayer.play()
        } else {
            avPlayer?.play()
        }
    }

    func pause() {
        if currentItem?.isMusic == true {
            musicPlayer.pause()
        } else {
            avPlayer?.pause()
        }
    }

    func next() {
        if currentItem?.isMusic == true {
            musicPlayer.skipToNextItem()
        } else {
            // Implement podcast next logic
        }
    }

    func previous() {
        if currentItem?.isMusic == true {
            musicPlayer.skipToPreviousItem()
        } else {
            // Implement podcast previous logic
        }
    }

    func playShuffledQueue() {
        isShuffleEnabled = true
        if currentItem?.isMusic == true {
            musicPlayer.shuffleMode = .songs
        }
        play()
    }

    func stopShuffle() {
        isShuffleEnabled = false
        if currentItem?.isMusic == true {
            musicPlayer.shuffleMode = .off
        }
    }

    func setQueue(with items: [MediaItem]) {
        self.items = items
        if let firstItem = items.first, firstItem.isMusic {
            let mpMediaItems = items.compactMap { convertToMPMediaItem($0) }
            let collection = MPMediaItemCollection(items: mpMediaItems)
            musicPlayer.setQueue(with: collection)
        } else {
            // Set up AVPlayer queue for podcasts
        }
        if !isShuffleEnabled {
            stopShuffle()
        }
    }

    func play(at index: Int) {
        guard index < items.count else { return }
        currentItem = items[index]
        if currentItem?.isMusic == true {
            if let mpMediaItem = convertToMPMediaItem(currentItem!) {
                musicPlayer.nowPlayingItem = mpMediaItem
            }
        } else if let url = currentItem?.url {
            avPlayer = AVPlayer(url: url)
        }
        play()
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateItemInfo), name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: musicPlayer)
        NotificationCenter.default.addObserver(self, selector: #selector(updatePlaybackState), name: .MPMusicPlayerControllerPlaybackStateDidChange, object: musicPlayer)
    }

    @objc private func updateItemInfo() {
        if let mpMediaItem = musicPlayer.nowPlayingItem {
            currentItem = convertToMediaItem(mpMediaItem)
        }
    }

    @objc private func updatePlaybackState() {
        isPlaying = musicPlayer.playbackState == .playing || (avPlayer?.timeControlStatus == .playing)
    }

    private func convertToMPMediaItem(_ mediaItem: MediaItem) -> MPMediaItem? {
        // Implement conversion from MediaItem to MPMediaItem
        return nil
    }

    private func convertToMediaItem(_ mpMediaItem: MPMediaItem) -> MediaItem {
        return MediaItem(
            id: mpMediaItem.persistentID.description,
            title: mpMediaItem.title ?? "",
            artist: mpMediaItem.artist ?? "",
            artwork: mpMediaItem.artwork?.image(at: CGSize(width: 100, height: 100)),
            isMusic: true,
            url: nil
        )
    }
}

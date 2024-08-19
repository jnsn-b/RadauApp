import Foundation
import MediaPlayer

class MusicPlayer: ObservableObject {
    private var player: MPMusicPlayerController
    @Published var isPlaying = false
    @Published var currentSong: MPMediaItem?

    private var items: [MPMediaItem] = []
    private var isShuffleEnabled = false  // Flag, um den Shuffle-Zustand zu speichern

    init() {
        player = MPMusicPlayerController.applicationMusicPlayer
        NotificationCenter.default.addObserver(self, selector: #selector(updateSongInfo), name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: player)
        NotificationCenter.default.addObserver(self, selector: #selector(updatePlaybackState), name: .MPMusicPlayerControllerPlaybackStateDidChange, object: player)
        player.beginGeneratingPlaybackNotifications()
        updateSongInfo()
        updatePlaybackState()
    }

    deinit {
        player.endGeneratingPlaybackNotifications()
        NotificationCenter.default.removeObserver(self)
    }

    func play() {
        player.play()
    }

    func pause() {
        player.pause()
    }

    func next() {
        player.skipToNextItem()
    }

    func previous() {
        player.skipToPreviousItem()
    }

    func playShuffledQueue() {
        isShuffleEnabled = true
        player.shuffleMode = .songs
        play()
    }

    func stopShuffle() {
        isShuffleEnabled = false
        player.shuffleMode = .off
    }

    @objc private func updateSongInfo() {
        currentSong = player.nowPlayingItem
    }

    @objc private func updatePlaybackState() {
        isPlaying = player.playbackState == .playing
    }

    func setQueue(with items: [MPMediaItem]) {
        self.items = items
        let collection = MPMediaItemCollection(items: items)
        player.setQueue(with: collection)
        if !isShuffleEnabled {
            stopShuffle()  // Deaktiviere Shuffle, wenn ein neuer Song manuell ausgewählt wird
        }
    }

    func play(at index: Int) {
        guard index < items.count else { return }
        player.nowPlayingItem = items[index]
        play()
    }
}

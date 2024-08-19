import Foundation
import MediaPlayer

class MusicPlayer: ObservableObject {
    private var player: MPMusicPlayerController
    @Published var isPlaying = false
    @Published var currentSong: MPMediaItem?
    
    private var items: [MPMediaItem] = []
    var isShuffleEnabled = false  // Flag, um den Shuffle-Zustand zu speichern

    init() {
        player = MPMusicPlayerController.applicationMusicPlayer
        setupNotifications()
        player.beginGeneratingPlaybackNotifications()
        updateSongInfo()
        updatePlaybackState()
    }

    deinit {
        // Beende das Empfangen von Benachrichtigungen und entferne den Beobachter, wenn die Instanz deinitialisiert wird
        player.endGeneratingPlaybackNotifications()
        NotificationCenter.default.removeObserver(self)
    }

    // Funktion zum Abspielen des aktuellen Songs
    func play() {
        player.play()
    }

    // Funktion zum Pausieren des aktuellen Songs
    func pause() {
        player.pause()
    }

    // Funktion zum Überspringen zum nächsten Song
    func next() {
        player.skipToNextItem()
    }

    // Funktion zum Zurückspringen zum vorherigen Song
    func previous() {
        player.skipToPreviousItem()
    }

    // Funktion zum Abspielen der Warteschlange im Shuffle-Modus
    func playShuffledQueue() {
        isShuffleEnabled = true
        player.shuffleMode = .songs
        play()
    }

    // Funktion zum Deaktivieren des Shuffle-Modus
    func stopShuffle() {
        isShuffleEnabled = false
        player.shuffleMode = .off
    }

    // Funktion zum Setzen der Wiedergabeliste/Warteschlange
    func setQueue(with items: [MPMediaItem]) {
        self.items = items
        let collection = MPMediaItemCollection(items: items)
        player.setQueue(with: collection)
        if !isShuffleEnabled {
            stopShuffle()  // Deaktiviere Shuffle, wenn eine neue Warteschlange gesetzt wird
        }
    }

    // Funktion zum Abspielen eines Songs an einem bestimmten Index in der Warteschlange
    func play(at index: Int) {
        guard index < items.count else { return }
        player.nowPlayingItem = items[index]
        play()
    }

    // Private Funktion zum Einrichten der Benachrichtigungen für Wiedergabe und Songwechsel
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateSongInfo), name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: player)
        NotificationCenter.default.addObserver(self, selector: #selector(updatePlaybackState), name: .MPMusicPlayerControllerPlaybackStateDidChange, object: player)
    }

    // Private Funktion zum Aktualisieren der aktuellen Song-Informationen
    @objc private func updateSongInfo() {
        currentSong = player.nowPlayingItem
    }

    // Private Funktion zum Aktualisieren des Wiedergabezustands (spielend oder pausiert)
    @objc private func updatePlaybackState() {
        isPlaying = player.playbackState == .playing
    }
}

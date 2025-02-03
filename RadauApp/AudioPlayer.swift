import Foundation
import MediaPlayer
import AVFoundation
import FeedKit

class AudioPlayer: ObservableObject {
    
    private var avPlayer: AVPlayer?
    private var avPlayerItem: AVPlayerItem?

    

    private var appleMusicPlayer: MPMusicPlayerController?

    @Published var isPlaying = false
    @Published var currentTitle: String = "Unbekannt"
    @Published var currentSource: String = ""
    @Published var isShuffleEnabled = false
    @Published var isUsingAppleMusic = false
    @Published var currentSong: MPMediaItem?
    @Published var artwork: UIImage? = nil
    @Published public var isRadioMode = false
    @Published public var isPodcastMode: Bool = false
    
    @Published var showPlayer: Bool = false 
    @Published var showMiniPlayer: Bool = true
    

    private var items: [MPMediaItem] = []

    @Published var currentPodcast: PodcastFetcher.Podcast?
    @Published var currentEpisode: PodcastFetcher.PodcastEpisode?
    @Published var currentEpisodeList: [PodcastFetcher.PodcastEpisode] = []
    

    init(useAppleMusic: Bool = false) {
        self.isUsingAppleMusic = useAppleMusic
        setupAudioSession()
        switchPlayer(toAppleMusic: useAppleMusic)
        
        if useAppleMusic {
            setupAppleMusicNotifications()
            appleMusicPlayer?.beginGeneratingPlaybackNotifications()
        } else {
            setupAVPlayerObservers() 
        }
    }

    // 🎵 Wechsel zwischen Apple Music, Podcast oder Radio
    func switchPlayer(toAppleMusic: Bool, isRadio: Bool = false, isPodcast: Bool = false) {
        isUsingAppleMusic = toAppleMusic
        isRadioMode = isRadio
        isPodcastMode = isPodcast

        if toAppleMusic {
            appleMusicPlayer = MPMusicPlayerController.applicationMusicPlayer
            avPlayer = nil
            print("🎵 Apple Music Player aktiviert.")
            setupAppleMusicNotifications()
        } else {
            appleMusicPlayer = nil
            avPlayer = AVPlayer()
            print("🎶 AVPlayer aktiviert.")
            setupAVPlayerObservers()
        }
    }
    
    func updateArtwork() {
        print("🔄 Update Artwork für Song: \(currentSong?.title ?? "Kein Song")")
        
        if let image = currentSong?.artwork?.image(at: CGSize(width: 300, height: 300)) {
            self.artwork = image
            print("🎨 Neues Artwork gesetzt!")
        } else {
            self.artwork = UIImage() // ✅ Stelle sicher, dass nie `nil` verwendet wird
            print("🎨 Kein Artwork vorhanden, Standardbild gesetzt")
        }
    }

    // 📻 Radio-Stream starten
    func playRadio(radio: Radio) {
        AudioSessionManager.shared.activateAVPlayerSession()
        var streamURL = radio.streamURL

        // Falls HTTP-Stream existiert, ersetze es mit HTTPS, falls möglich
        if streamURL.hasPrefix("http://") {
            let secureURL = streamURL.replacingOccurrences(of: "http://", with: "https://")
            canPlayURL(secureURL) { isPlayable in
                if isPlayable {
                    streamURL = secureURL
                }
                self.startRadioPlayback(from: streamURL, radio: radio)
            }
        } else {
            startRadioPlayback(from: streamURL, radio: radio)
        }
    }

    // 🔄 Startet die Radio-Wiedergabe mit einer URL
    private func startRadioPlayback(from urlString: String, radio: Radio) {
        guard let url = URL(string: urlString) else {
            print("❌ Ungültige Stream-URL: \(urlString)")
            return
        }

        print("▶️ Starte Radio-Stream: \(urlString)")

        self.currentSource = radio.name
        self.currentTitle = "Live-Stream"
        self.isRadioMode = true
        self.isPodcastMode = false
        self.isUsingAppleMusic = false
        self.avPlayer = AVPlayer(url: url)
        self.avPlayer?.play()
        self.isPlaying = true
        
        updateRadioArtwork(for: radio)

        print("✅ Radio-Wiedergabe gestartet: \(radio.name)")
    }
    
    func updateRadioArtwork(for radio: Radio) {
        print("🔄 Lade Artwork für Sender: \(radio.name)")

        // 1️⃣ Falls `artworkData` existiert, konvertiere es zu einem Bild
        if let data = radio.artworkData, let image = UIImage(data: data) {
            self.artwork = image
            print("🎨 Sender-Logo aus `artworkData` geladen für \(radio.name)")
            return
        }

        // 2️⃣ Falls ein `artworkFilePath` existiert, lade das Bild von dort
        if let filePath = radio.artworkFilePath {
            let fileURL = URL(fileURLWithPath: filePath)
            if let imageData = try? Data(contentsOf: fileURL), let image = UIImage(data: imageData) {
                self.artwork = image
                print("🎨 Sender-Logo aus Datei geladen für \(radio.name)")
                return
            }
        }

        // 4️⃣ Falls kein Logo verfügbar ist, Standardbild setzen
        self.artwork = UIImage(systemName: "antenna.radiowaves.left.and.right")
        print("❌ Keine Logo-Quelle verfügbar, Standardbild gesetzt.")
    }
    

    // 🎙 Podcast starten
    func playPodcast(episode: PodcastFetcher.PodcastEpisode, podcast: PodcastFetcher.Podcast) {
        print("▶️ Spiele Podcast-Episode: \(episode.title) aus \(podcast.name)")

        self.currentEpisode = episode
        self.currentPodcast = podcast 
        self.currentTitle = episode.title
        self.currentSource = podcast.name
        self.isPodcastMode = true
        self.isRadioMode = false
        self.isUsingAppleMusic = false

        // ✅ Sicherstellen, dass `currentPodcast?.episodes` gesetzt ist
        if self.currentEpisodeList.isEmpty {
                self.currentEpisodeList = podcast.episodes
                print("📌 `currentEpisodeList` gesetzt mit \(podcast.episodes.count) Episoden.")
            } else {
                print("📌 `currentEpisodeList` bereits vorhanden.")
            }

        guard let url = URL(string: episode.playbackURL) else {
            print("❌ Ungültige URL für Episode: \(episode.title)")
            return
        }

        let playerItem = AVPlayerItem(url: url)
        self.avPlayer = AVPlayer(playerItem: playerItem)
        self.avPlayer?.play()
        self.isPlaying = true

        updatePodcastArtwork()
        
        extractID3Image(from: url) { [weak self] image in
                    DispatchQueue.main.async {
                        self?.artwork = image ?? UIImage(systemName: "mic.fill")
                        print(image != nil ? "🎨 ID3-Tag Artwork gesetzt" : "❌ Kein ID3-Tag Artwork gefunden")
                    }
                }
    }
    
    func updatePodcastArtwork() {
        guard let podcast = currentPodcast else {
            print("❌ Kein aktuelles Podcast-Objekt, Standardbild gesetzt.")
            self.artwork = UIImage(systemName: "mic.fill")
            return
        }
        
        print("🔄 Lade Podcast-Artwork für: \(podcast.name)")
        
        // 1️⃣ Falls `artworkFilePath` existiert, lade das Bild
        if let artworkPath = podcast.artworkFilePath {
            let fileURL = URL(fileURLWithPath: artworkPath)
            if let imageData = try? Data(contentsOf: fileURL), let image = UIImage(data: imageData) {
                self.artwork = image
                print("🎨 Podcast-Logo aus Datei geladen für \(podcast.name)")
                return
            }
        

        // 2️⃣ Falls kein Artwork vorhanden, setze ein Standardbild
        self.artwork = UIImage(systemName: "mic.fill")
        print("❌ Keine Podcast-Artwork-Quelle gefunden, Standardbild gesetzt.")
    }

        // 2️⃣ Falls kein Artwork vorhanden, setze ein Standardbild
        self.artwork = UIImage(systemName: "mic.fill")
        print("❌ Keine Podcast-Artwork-Quelle gefunden, Standardbild gesetzt.")
    }

    // ⏭ Nächste Episode
    func nextPodcastEpisode() {
        print("⏭ Versuche, nächste Podcast-Episode zu spielen...")

        guard let currentEpisode = currentEpisode else {
            print("❌ Fehler: `currentEpisode` ist nil!")
            return
        }

        guard let podcast = currentPodcast else {
            print("❌ Fehler: `currentPodcast` ist nil!")
            return
        }

        let episodes = currentEpisodeList // ✅ Nutze `currentEpisodeList`

        if episodes.isEmpty {
            print("❌ Fehler: `currentEpisodeList` ist leer!")
            return
        }

        print("📻 Episoden-Liste enthält \(episodes.count) Einträge:")
        for ep in episodes {
            print("  ▶️ \(ep.title) – ID: \(ep.id)")
        }

        guard let currentIndex = episodes.firstIndex(where: { $0.id == currentEpisode.id }) else {
            print("❌ Fehler: Konnte aktuelle Episode nicht in `currentEpisodeList` finden!")
            return
        }

        print("📻 Aktuelle Episode Index: \(currentIndex) von \(episodes.count - 1)")

        guard currentIndex + 1 < episodes.count else {
            print("⏭ Keine weitere Episode vorhanden!")
            return
        }

        let nextEpisode = episodes[currentIndex + 1]
        print("✅ Nächste Episode: \(nextEpisode.title) wird abgespielt!")

        playPodcast(episode: nextEpisode, podcast: podcast) // ✅ Lädt automatisch aus `currentEpisodeList`
    }

    // ⏮ Vorherige Episode
    func previousPodcastEpisode(episodes: [PodcastFetcher.PodcastEpisode]) {
        guard let currentEpisode = currentEpisode,
              let podcast = currentPodcast, // ✅ Sicherstellen, dass das Podcast-Objekt existiert
              let currentIndex = episodes.firstIndex(where: { $0.id == currentEpisode.id }),
              currentIndex - 1 >= 0 else { return }

        let previousEpisode = episodes[currentIndex - 1]
        playPodcast(episode: previousEpisode, podcast: podcast) // ✅ Podcast-Objekt mit übergeben
    }

    // ⏹ Stoppen (Radio, Podcast & AVPlayer)
    func stop() {
        if isUsingAppleMusic {
            appleMusicPlayer?.stop()
        } else {
            avPlayer?.pause()
            avPlayer?.seek(to: .zero)
        }
        isPlaying = false
        isPodcastMode = false
        isRadioMode = false
        print("⏹ Wiedergabe gestoppt")
    }

    // ⏩ Skip Forward (Podcasts)
    func skipForward(seconds: TimeInterval) {
        if let currentTime = avPlayer?.currentTime() {
            let newTime = currentTime + CMTime(seconds: seconds, preferredTimescale: 1)
            avPlayer?.seek(to: newTime)
        }
    }

    // ⏪ Skip Backward (Podcasts)
    func skipBackward(seconds: TimeInterval) {
        if let currentTime = avPlayer?.currentTime() {
            let newTime = currentTime - CMTime(seconds: seconds, preferredTimescale: 1)
            avPlayer?.seek(to: newTime)
        }
    }

    // 🎶 Apple Music Steuerung
    func play() {
        if isUsingAppleMusic {
            print("▶️ Play gedrückt für Apple Music...")
            appleMusicPlayer?.play()
            print("🎵 Apple Music Status nach play(): \(appleMusicPlayer?.playbackState.rawValue)")
            
        } else {
            avPlayer?.play()
        }
        isPlaying = true
        updateArtwork()
    }
    
    func play(at index: Int?) {
        guard let index = index, index >= 0, index < items.count else { return }
        let item = items[index]

        if isUsingAppleMusic {
            print("▶️ Play mit Queue gedrückt für Apple Music...")
            appleMusicPlayer?.nowPlayingItem = item
            appleMusicPlayer?.play()
        } else {
            avPlayer?.pause()
            if let url = item.assetURL {
                avPlayer = AVPlayer(url: url)
                avPlayer?.play()
            }
        }
        currentSong = item
        updateArtwork()
        isPlaying = true
        isShuffleEnabled = false
        }

    func setQueue(with items: [MPMediaItem]) {
        guard !items.isEmpty else {
            print("❌ Keine Songs in der Warteschlange!")
            return
        }
        self.items = items

        if isUsingAppleMusic {
            appleMusicPlayer?.setQueue(with: MPMediaItemCollection(items: items))
            appleMusicPlayer?.nowPlayingItem = items.first
        } else {
            avPlayer?.pause()
            if let url = items.first?.assetURL {
                let playerItem = AVPlayerItem(url: url)
                avPlayer = AVPlayer(playerItem: playerItem)
            }
        }
        currentSong = items.first  // ✅ Aktualisiert `currentSong`
    }
    
    func playShuffledQueue() {
        guard !items.isEmpty else {
            return } // ❌ Falls keine Songs geladen sind, nichts tun
        isShuffleEnabled = true
        let shuffledItems = items.shuffled()
        setQueue(with: shuffledItems)
        play()
    }
    
    func pause() {
        if isUsingAppleMusic {
            appleMusicPlayer?.pause()
        } else {
            avPlayer?.pause()
        }
        isPlaying = false
    }

    func next() {
        if isUsingAppleMusic {
            appleMusicPlayer?.skipToNextItem()
        }
        updateArtwork()
    }

    func previous() {
        if isUsingAppleMusic {
            appleMusicPlayer?.skipToPreviousItem()
        } else {
            if isPodcastMode, let episode = currentEpisode {
                // Springe zur vorherigen Podcast-Episode
                previousPodcastEpisode(episodes: []) // Füge hier eine echte Episodenliste ein
            } else {
                avPlayer?.seek(to: .zero)
            }
        }
        updateArtwork()
    }

    // 🔍 Prüft, ob eine URL spielbar ist
    private func canPlayURL(_ urlString: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"

        URLSession.shared.dataTask(with: request) { _, response, _ in
            let isPlayable = (response as? HTTPURLResponse)?.statusCode == 200
            DispatchQueue.main.async {
                completion(isPlayable)
            }
        }.resume()
    }

    // 📡 Apple Music Status-Updates
    private func setupAppleMusicNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateSongInfo), name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: appleMusicPlayer)
        NotificationCenter.default.addObserver(self, selector: #selector(updatePlaybackState), name: .MPMusicPlayerControllerPlaybackStateDidChange, object: appleMusicPlayer)
        appleMusicPlayer?.beginGeneratingPlaybackNotifications()  // ✅ Stellt sicher, dass Events registriert werden
    }
    
    @objc private func updatePlaybackState() {
        isPlaying = appleMusicPlayer?.playbackState == .playing
    }

    @objc private func updateSongInfo() {
        guard let song = appleMusicPlayer?.nowPlayingItem else { return }
        currentTitle = song.title ?? "Unbekannt"
        currentSource = song.artist ?? "Unbekannt"
        currentSong = song
        updateArtwork()
    }

    // 🎧 AVPlayer Status-Updates
    private func setupAVPlayerObservers() {
        avPlayer?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 600), queue: .main) { [weak self] time in
            self?.currentTitle = "Streaming..."
        }
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ Audio-Session erfolgreich aktiviert!")
        } catch {
            print("❌ Fehler beim Aktivieren der Audio-Session: \(error.localizedDescription)")
        }
    }
    
    private func extractID3Image(from url: URL, completion: @escaping (UIImage?) -> Void) {
            let asset = AVAsset(url: url)
            asset.loadValuesAsynchronously(forKeys: ["commonMetadata"]) {
                let metadata = asset.commonMetadata
                
                for item in metadata {
                    if item.commonKey == .commonKeyArtwork, let data = item.dataValue, let image = UIImage(data: data) {
                        completion(image)
                        return
                    }
                }
                completion(nil) // Falls kein Bild gefunden wird
            }
        }
}

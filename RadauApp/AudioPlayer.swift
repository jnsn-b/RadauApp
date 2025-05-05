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
       // AudioSessionManager.shared.activateAVPlayerSession()
        switchPlayer(toAppleMusic: useAppleMusic)
        setupRemoteTransportControls()
        if useAppleMusic {
            setupNowPlayingNotifications()
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
            setupNowPlayingNotifications()
        } else {
            appleMusicPlayer = nil
            avPlayer = AVPlayer()
            print("🎶 AVPlayer aktiviert.")
            setupAVPlayerObservers()
        }
        setupRemoteTransportControls()
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
        setupNowPlayingNotifications()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [:]
        var streamURL = radio.streamURL
        
        isShuffleEnabled = false

        // Falls HTTP-Stream existiert, ersetze es mit HTTPS, falls möglich
        if streamURL.hasPrefix("http://") {
            let secureURL = streamURL.replacingOccurrences(of: "http://", with: "https://")
            canPlayURL(secureURL) { isPlayable in
                if isPlayable {
                    streamURL = secureURL
                }
                self.startRadioPlayback(from: streamURL, radio: radio)
                self.setupNowPlayingNotifications()
            }
        } else {
            startRadioPlayback(from: streamURL, radio: radio)
            self.setupNowPlayingNotifications()
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

        // Platzhalter-Artwork setzen
           let placeholderImage = UIImage(systemName: "antenna.radiowaves.left.and.right")
           self.artwork = placeholderImage
        
        // 🔄 Metadaten für Now Playing setzen
        var nowPlayingInfo: [String: Any] = [:]
        nowPlayingInfo[MPMediaItemPropertyTitle] = "Live-Stream"
        nowPlayingInfo[MPMediaItemPropertyArtist] = radio.name
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0

        // Platzhalter-Artwork hinzufügen
            if let artworkImage = artwork {
                let artwork = MPMediaItemArtwork(boundsSize: artworkImage.size) { _ in return artworkImage }
                nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
            }
        
        // Falls ein Sender-Logo existiert, füge es hinzu
        if let artworkImage = artwork {
            let artwork = MPMediaItemArtwork(boundsSize: artworkImage.size) { _ in return artworkImage }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }

        // ✅ MPNowPlayingInfoCenter setzen
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        updateNowPlayingInfo()
        // Überprüfe die aktuellen Werte
        if let currentInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo {
            print("✅ Aktuelle NowPlayingInfo: \(currentInfo)")
        } else {
            print("❌ Keine NowPlayingInfo gesetzt.")
        }

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
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [:]
        AudioSessionManager.shared.activateAVPlayerSession()
        print("▶️ Spiele Podcast-Episode: \(episode.title) aus \(podcast.name)")

        self.currentEpisode = episode
        self.currentPodcast = podcast
        self.currentTitle = episode.title
        self.currentSource = podcast.name
        self.isPodcastMode = true
        self.isRadioMode = false
        self.isUsingAppleMusic = false

        isShuffleEnabled = false
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
        updateNowPlayingInfo()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
        self.isPlaying = true

        updatePodcastArtwork()
        
        extractID3Image(from: url) { [weak self] image in
            DispatchQueue.main.async {
                if image != nil {
                    self?.artwork = image ?? UIImage(systemName: "mic.fill")
                    print("🎨 ID3-Tag Artwork gesetzt")
                } else {
                    print("❌ Kein ID3-Tag Artwork gefunden, Podcast Artwork bleibt")
                }
                self?.updateNowPlayingInfo()
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
    func nextPodcastEpisode(episodes: [PodcastFetcher.PodcastEpisode]) {
        guard let currentEpisode = currentEpisode,
              let podcast = currentPodcast,
              let currentIndex = episodes.firstIndex(where: { $0.id == currentEpisode.id }),
              currentIndex + 1 < episodes.count else { return } 

        let nextEpisode = episodes[currentIndex + 1]
        playPodcast(episode: nextEpisode, podcast: podcast)
    }

    // ⏮ Vorherige Episode
    func previousPodcastEpisode(episodes: [PodcastFetcher.PodcastEpisode]) {
        guard let currentEpisode = currentEpisode,
              let podcast = currentPodcast,
              let currentIndex = episodes.firstIndex(where: { $0.id == currentEpisode.id }),
              currentIndex - 1 >= 0 else { return }

        let previousEpisode = episodes[currentIndex - 1]
        playPodcast(episode: previousEpisode, podcast: podcast)
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

    
    func play() {
        if isUsingAppleMusic {
            print("▶️ Play gedrückt für Apple Music...")
            appleMusicPlayer?.play()
            print("🎵 Apple Music Status nach play(): \(appleMusicPlayer?.playbackState.rawValue)")
            
        } else {
            avPlayer?.play()
            updateNowPlayingInfo()
            isShuffleEnabled = false
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
            isShuffleEnabled = false
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
    private func setupNowPlayingNotifications() {
        if isUsingAppleMusic {
            NotificationCenter.default.addObserver(self, selector: #selector(updateNowPlayingInfo), name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: appleMusicPlayer)
            NotificationCenter.default.addObserver(self, selector: #selector(updateNowPlayingState), name: .MPMusicPlayerControllerPlaybackStateDidChange, object: appleMusicPlayer)
            appleMusicPlayer?.beginGeneratingPlaybackNotifications()
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(updateNowPlayingInfo), name: .AVPlayerItemNewAccessLogEntry, object: avPlayer?.currentItem)
            NotificationCenter.default.addObserver(self, selector: #selector(updateNowPlayingState), name: .AVPlayerItemDidPlayToEndTime, object: avPlayer?.currentItem)
        }
    }
    
    @objc private func updateNowPlayingState() {
        if isUsingAppleMusic {
            isPlaying = appleMusicPlayer?.playbackState == .playing
        } else {
            isPlaying = avPlayer?.rate != 0
        }
    }
    
    @objc private func updateNowPlayingInfo() {
        print("🔄 updateNowPlayingInfo wurde aufgerufen!")

        var nowPlayingInfo: [String: Any] = [:]

        if isUsingAppleMusic {
            guard let song = appleMusicPlayer?.nowPlayingItem else {
                print("❌ Kein Song in Apple Music gefunden")
                return
            }
            currentTitle = song.title ?? "Unbekannt"
            currentSource = song.artist ?? "Unbekannt"
            nowPlayingInfo[MPMediaItemPropertyTitle] = currentTitle
            nowPlayingInfo[MPMediaItemPropertyArtist] = currentSource
        } else {
            if isRadioMode {
                print("📻 Radio-Modus erkannt")
                currentTitle = "Live-Stream"
                nowPlayingInfo[MPMediaItemPropertyTitle] = "Live-Stream"
                nowPlayingInfo[MPMediaItemPropertyArtist] = currentSource
            } else if let episode = currentEpisode, let podcast = currentPodcast {
                print("🎙 Podcast erkannt: \(episode.title) aus \(podcast.name)")
                currentTitle = episode.title
                currentSource = podcast.name
                nowPlayingInfo[MPMediaItemPropertyTitle] = episode.title
                nowPlayingInfo[MPMediaItemPropertyArtist] = podcast.name
            } else {
                print("🎶 AVPlayer Streaming-Modus erkannt")
                currentTitle = "Streaming..."
                nowPlayingInfo[MPMediaItemPropertyTitle] = "Streaming..."
            }
            // Zeitinformationen für AVPlayer/Podcast/Radio ergänzen
            if let player = avPlayer, let currentItem = player.currentItem {
                let currentTime = player.currentTime().seconds
                let duration = currentItem.asset.duration.seconds
                if duration.isFinite {
                    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
                    nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
                }
            }
        }

        // 🔄 Cover setzen, falls verfügbar
        if let artworkImage = artwork {
            let artwork = MPMediaItemArtwork(boundsSize: artworkImage.size) { _ in return artworkImage }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        } else {
            print("❌ Kein Artwork verfügbar")
        }

        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

        // ✅ Korrektes Setzen der Metadaten
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        print("✅ MPNowPlayingInfoCenter wurde aktualisiert: \(nowPlayingInfo)")
    }


    
    // 🎧 AVPlayer Status-Updates
    private func setupAVPlayerObservers() {
        avPlayer?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 600), queue: .main) { [weak self] time in
            self?.currentTitle = "Streaming..."
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
    // 🔊 Remote Transport Controls für Sperrbildschirm & Control Center
    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] event in
            self?.play()
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] event in
            self?.pause()
            return .success
        }
    }
}

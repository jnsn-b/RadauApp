import MediaPlayer
import SwiftUI

struct PodcastDetailView: View {
    @EnvironmentObject var playerUI: PlayerUIState
    @EnvironmentObject var audioPlayer: AudioPlayer
    @Binding var podcast: PodcastFetcher.Podcast
    @State private var episodes: [PodcastFetcher.PodcastEpisode] = []
    @State private var isPlaying: Bool = false
    @StateObject private var podcastFetcher = PodcastFetcher()
    @ObservedObject var podcastStore: PodcastStore
    
    @State private var displayedEpisodes: Int = 20
    @State private var isLoading = false

    init(podcast: Binding<PodcastFetcher.Podcast>, podcastStore: PodcastStore) {
            self._podcast = podcast
            self.podcastStore = podcastStore
            loadEpisodesFromStore()
        }

    var body: some View {
        VStack {
            episodesList
            
         
        }
        .onAppear(perform: loadEpisodesFromStore)
        .background(ScreenPainter.primaryColor.edgesIgnoringSafeArea(.all))
        .navigationBarTitle($podcast.wrappedValue.name ?? "Podcast", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    podcastArtwork(width: 24, height: 24) // Klein für die Navigation Bar
                    
                    Text($podcast.wrappedValue.name ?? "Podcast")
                        .font(.headline)
                }
            }
        }
        .onChange(of: audioPlayer.isPlaying) { newValue in
            isPlaying = newValue
        }
    }

    /// 🎨 Flexible Funktion für Podcast-Artwork mit variabler Größe
    private func podcastArtwork(width: CGFloat, height: CGFloat) -> some View {
        Group {
            if let artworkPath = podcast.artworkFilePath,
               FileManager.default.fileExists(atPath: artworkPath),
               let imageData = try? Data(contentsOf: URL(fileURLWithPath: artworkPath)),
               let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit) // Bild wird nicht verzerrt
                    .frame(width: width, height: height) // Dynamische Größe
            } else {
                Image(systemName: "mic.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: width, height: height)
                    .foregroundColor(.gray)
            }
        }
    }

    private var episodesList: some View {
        List {
            ForEach(episodes.prefix(displayedEpisodes)) { episode in
                HStack {
                    VStack(alignment: .leading) {
                        Text(episode.title)
                            .font(.headline)
                        Text("\(episode.durationInMinutes) Min.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .onTapGesture {
                    audioPlayer.playPodcast(episode: episode, podcast: podcast)
                    isPlaying = true
                    playerUI.showPlayer = true
                }
            }

            // 🔄 **Lade mehr Episoden beim Scrollen nach unten**
            if displayedEpisodes < episodes.count {
                HStack {
                    Spacer()
                    ProgressView()  // ⏳ Lade-Indikator
                    Spacer()
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        displayedEpisodes += 20  // 👈 Lade 20 weitere Episoden
                    }
                }
            }
        }
    }

    private func loadEpisodesFromStore() {
        if let storedPodcast = podcastStore.podcasts.first(where: { $0.id == podcast.id }) {
            self.episodes = storedPodcast.episodes
            print("📌 Episoden aus `PodcastStore` geladen: \(episodes.count) Episoden.")
            
            if storedPodcast.episodes.isEmpty, !isLoading { // 🛑 Doppelte Requests verhindern
                print("⚠️ Podcast gefunden, aber keine Episoden gespeichert! Lade jetzt nach...")
                
                isLoading = true  // 🔄 Setze Ladezustand

                Task {
                    await podcastStore.loadEpisodes()
                    DispatchQueue.main.async {
                        if let updatedPodcast = podcastStore.podcasts.first(where: { $0.id == podcast.id }) {
                            self.episodes = updatedPodcast.episodes
                            print("✅ Episoden nachgeladen: \(episodes.count) Episoden.")
                        }
                        isLoading = false  // ✅ Ladezustand zurücksetzen
                    }
                }
            }
        } else {
            print("⚠️ Podcast nicht im `PodcastStore`. Ladevorgang startet...")
            if !isLoading {  // 🛑 Verhindert mehrfachen Ladevorgang
                isLoading = true
                Task {
                    await podcastStore.loadEpisodes()
                    isLoading = false
                }
            }
        }
    }
}

extension PodcastFetcher.PodcastEpisode {
    var durationInMinutes: Int {
        Int(Double(playbackDurationString) ?? 0) / 60
    }
}

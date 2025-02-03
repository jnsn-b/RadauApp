import MediaPlayer
import SwiftUI

struct PodcastDetailView: View {
    @EnvironmentObject var playerUI: PlayerUIState
    @EnvironmentObject var audioPlayer: AudioPlayer
    @Binding var podcast: PodcastFetcher.Podcast
    @State private var episodes: [PodcastFetcher.PodcastEpisode] = []
    @State private var isPlaying: Bool = false
    @StateObject private var podcastFetcher = PodcastFetcher()

    init(podcast: Binding<PodcastFetcher.Podcast>) {
        self._podcast = podcast
        fetchEpisodes()
    }

    var body: some View {
        VStack {
            episodesList
            //tst
         
        }
        .onAppear(perform: fetchEpisodes)
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
        List(episodes) { episode in
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
    }

    private func fetchEpisodes() {
        Task {
            let fetchedEpisodes = await podcastFetcher.fetchEpisodes(from: podcast.feedURL, podcast: podcast)

            DispatchQueue.main.async {
                self.episodes = fetchedEpisodes
            }
        }
    }
}

extension PodcastFetcher.PodcastEpisode {
    var durationInMinutes: Int {
        Int(Double(playbackDurationString) ?? 0) / 60
    }
}

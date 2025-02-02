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
            podcastArtwork

            Text(podcast.name)
                .font(.title)
                .fontWeight(.bold)
                .padding()

            episodesList
            

            // ✅ `PlayerView` statt `playerControls`
            if playerUI.showPlayer || audioPlayer.isPlaying {
                PlayerView()
                    .environmentObject(audioPlayer)
                    .environmentObject(playerUI)
                    .edgesIgnoringSafeArea(.bottom)
            }
            
        }
        
        .onAppear(perform: fetchEpisodes)
        .onChange(of: audioPlayer.isPlaying) { newValue in
            isPlaying = newValue

        }
        
    }

    private var podcastArtwork: some View {
        Group {
            if let artworkPath = podcast.artworkFilePath,
               FileManager.default.fileExists(atPath: artworkPath),
               let imageData = try? Data(contentsOf: URL(fileURLWithPath: artworkPath)),
               let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .cornerRadius(10)
            } else {
                Image(systemName: "mic.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
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

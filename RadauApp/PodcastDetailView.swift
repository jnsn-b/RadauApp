import SwiftUI

struct PodcastDetailView: View {
    @State private var podcast: PodcastFetcher.Podcast  // Ändere dies von let zu @State
    @State private var episodes: [PodcastFetcher.PodcastEpisode] = []
    @State private var currentEpisode: PodcastFetcher.PodcastEpisode?
    @StateObject private var podcastPlayer = PodcastPlayer()
    
    
    var body: some View {
        VStack {
            podcastArtwork

            Text(podcast.name)
                .font(.title)
                .fontWeight(.bold)
                .padding()

            episodesList

            playerControls
        }
        .onAppear(perform: fetchEpisodes)
    }
    
    private var podcastArtwork: some View {
        Group {
            if let data = podcast.artworkData, let image = UIImage(data: data) {
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
                podcastPlayer.play(episode: episode)
                currentEpisode = episode
            }
        }
    }
    
    private var playerControls: some View {
        HStack {
            Button("Vorherige") {
                if let episode = currentEpisode {
                    podcastPlayer.previous(episodes: episodes, currentEpisode: episode)
                }
            }
            Button("Nächste") {
                if let episode = currentEpisode {
                    podcastPlayer.next(episodes: episodes, currentEpisode: episode)
                }
            }

            Button("Stoppen") {
                podcastPlayer.stop()
                currentEpisode = nil
            }
        }
        .padding()
    }

    private func fetchEpisodes() {
        // Entfernen des 'if let', da 'podcast' bereits ein existierendes Objekt ist
        PodcastFetcher.fetchEpisodes(from: podcast.rssFeedURL, podcast: podcast) { updatedPodcast, fetchedEpisodes in
            self.episodes = fetchedEpisodes
            self.podcast = updatedPodcast
        }
    }
}

extension PodcastFetcher.PodcastEpisode {
    var durationInMinutes: Int {
        Int(Double(playbackDurationString) ?? 0) / 60
    }
}




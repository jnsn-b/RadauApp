import MediaPlayer
import SwiftUI

struct PodcastDetailView: View {
    
    @State private var podcast: PodcastFetcher.Podcast
    @State private var episodes: [PodcastFetcher.PodcastEpisode] = []
    @StateObject private var podcastPlayer = PodcastPlayer()
    @State private var isPlaying: Bool = false

    init(initialPodcast: PodcastFetcher.Podcast) {
        _podcast = State(initialValue: initialPodcast)
    }

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
        .onChange(of: podcastPlayer.player?.timeControlStatus) { status in
            isPlaying = status == .playing
        }
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
                isPlaying = true
            }
        }
    }

    private var playerControls: some View {
        HStack {
            Button(action: {
                if let currentEpisode = podcastPlayer.currentEpisode {
                    podcastPlayer.previous(episodes: episodes, currentEpisode: currentEpisode)
                }
            }) {
                Image(systemName: "backward.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
            }

            Spacer()

            Button(action: {
                if isPlaying {
                    podcastPlayer.player?.pause()
                } else {
                    podcastPlayer.player?.play()
                }
                isPlaying.toggle()
            }) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
            }

            Spacer()

            Button(action: {
                if let currentEpisode = podcastPlayer.currentEpisode {
                    podcastPlayer.next(episodes: episodes, currentEpisode: currentEpisode)
                }
            }) {
                Image(systemName: "forward.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(10)
    }

    private func fetchEpisodes() {
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

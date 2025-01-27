import SwiftUI
import UIKit
import Foundation
import MediaPlayer

struct MainView: View {
    @State private var selectedTab: Int = 0
    @StateObject private var authChecker = AuthorizationChecker()
    @StateObject private var podcastFetcher = PodcastFetcher()
    @ObservedObject var miniPlayerManager = ScreenPainter.miniPlayerManager
    @StateObject private var playlistFetcher = PlaylistFetcher()
    @State private var selectedPodcastURL: String? = nil
    @State private var showPodcastDetail: Bool = false
    @State private var showAddPodcastDialog: Bool = false
    @State private var episodes: [PodcastFetcher.PodcastEpisode] = []
    @State private var selectedPodcastTitle: String? = nil
    @State private var podcastImageData: Data? = nil
    @StateObject private var podcastStore = PodcastStore()

    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    func loadCustomFont(name: String, size: CGFloat) -> Font {
        if let uiFont = UIFont(name: name, size: size) {
            return Font(uiFont)
        } else {
            return Font.system(size: size)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                NavigationView {
                    VStack {
                        Picker("Kategorie", selection: $selectedTab) {
                            Text("🎵 Musik").tag(0)
                            Text("🎙️ Shows").tag(1)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()
                        
                        if selectedTab == 0 {
                            musicView()
                        } else {
                            PodcastView(podcastStore: podcastStore)
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Deine RadauApp")
                                .font(loadCustomFont(name: "KristenITC-Regular", size: 24))
                                .foregroundColor(ScreenPainter.textColor)
                        }
                    }
                    .background(ScreenPainter.backgroundColor.edgesIgnoringSafeArea(.all))
                }
                ScreenPainter.renderMiniPlayer()
            }
            .background(ScreenPainter.backgroundColor.edgesIgnoringSafeArea(.all))
            .onAppear {
                DispatchQueue.main.async {
                    authChecker.checkAppleMusicAuthorization()
                }
            }
            .sheet(isPresented: $miniPlayerManager.showPlayer) {
                MusicPlayerView(musicPlayer: miniPlayerManager.musicPlayer, showMiniPlayer: $miniPlayerManager.showMiniPlayer)
            }
        }
    }
    
    func musicView() -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(playlistFetcher.playlists, id: \.persistentID) { playlist in
                    ScreenPainter.playlistCardView(for: playlist)
                        .frame(height: 180)
                        .onTapGesture {
                            DispatchQueue.main.async {
                                miniPlayerManager.musicPlayer.setQueue(with: playlist.items)
                                if let firstItem = playlist.items.first {
                                    miniPlayerManager.musicPlayer.play(at: playlist.items.firstIndex(of: firstItem) ?? 0)
                                    miniPlayerManager.maximizePlayer()
                                }
                            }
                        }
                }
            }
            .padding()
        }
        .onAppear {
            playlistFetcher.fetchPlaylists()
        }
    }
    
    func loadPodcastEpisodes(for podcast: PodcastFetcher.Podcast) {
        print("Versuche, Episoden für Podcast mit URL: \(podcast.rssFeedURL) zu laden")

        PodcastFetcher.fetchEpisodes(from: podcast.rssFeedURL, podcast: podcast) { updatedPodcast, fetchedEpisodes in
            print("Episoden geladen: \(fetchedEpisodes.count)")
            self.episodes = fetchedEpisodes
            self.podcastImageData = updatedPodcast.artworkData
            self.selectedPodcastTitle = updatedPodcast.name
        }
    }
}

struct PodcastView: View {
    @ObservedObject var podcastStore: PodcastStore
    @State private var showAddPodcastDialog = false
    
    let columns = [GridItem(.adaptive(minimum: 150))]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                Button(action: {
                    showAddPodcastDialog = true
                }) {
                    VStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        Text("Neuen Podcast hinzufügen")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .frame(height: 200)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                }
                if podcastStore.podcasts.isEmpty {
                    Text("Keine Podcasts gefunden.")
                } else {
                    ForEach(podcastStore.podcasts, id: \.id) { podcast in
                        NavigationLink(destination: PodcastDetailView(initialPodcast: podcast)) {
                            PodcastCardView(podcast: podcast)
                        }
                    }
                }
            }
            .padding()
        }
        .background(ScreenPainter.backgroundColor.edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $showAddPodcastDialog) {
            AddPodcastView(showAddPodcastDialog: $showAddPodcastDialog)
        }

        .onAppear {
            podcastStore.loadPodcasts()
        }
    }
}



struct PodcastCardView: View {
    @State private var podcastImage: UIImage?
    let podcast: PodcastFetcher.Podcast

    var body: some View {
        VStack {
            Group {
                if let image = podcastImage {
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
            .frame(height: 120)

            Text(podcast.name)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 4)
        }
        .frame(height: 200)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
        .onAppear {
            loadPic()
        }
    }

    private func loadPic() {
        PodcastFetcher.loadPodcastArtwork(for: podcast) { image in
            DispatchQueue.main.async {
                self.podcastImage = image
            }
        }
    }
}

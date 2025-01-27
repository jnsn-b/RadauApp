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
    @ObservedObject private var radioFetcher = RadioFetcher()
    @State private var showAddRadioDialog: Bool = false
    @State private var selectedRadio: Radio? = nil
    @State var currentRadio: Radio? = nil
    @State private var currentRadioID: String? = nil


    
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
                            Text("🎙️ Podcasts").tag(1)
                            Text("📻 Radio").tag(2)
                            
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()
                        
                        if selectedTab == 0 {
                            musicView()
                        } else if selectedTab == 1 {
                            PodcastView(podcastStore: podcastStore, podcastFetcher: podcastFetcher)
                        } else {
                            radioView(radioFetcher: radioFetcher, showAddRadioDialog: $showAddRadioDialog, currentRadio: $currentRadio, currentRadioID: $currentRadioID)
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
        print("Versuche, Episoden für Podcast mit URL: \(podcast.feedURL) zu laden")

        Task {
            let fetchedEpisodes = await podcastFetcher.fetchEpisodes(from: podcast.feedURL, podcast: podcast) // ✅ Instanz-Aufruf mit `await`

            DispatchQueue.main.async {
                print("Episoden geladen: \(fetchedEpisodes.count)")
                self.episodes = fetchedEpisodes

                // ✅ Falls ein Bildpfad existiert, lade das Bild aus dem Dateisystem
                if let artworkPath = podcast.artworkFilePath {
                    do {
                        let imageData = try Data(contentsOf: URL(fileURLWithPath: artworkPath))
                        self.podcastImageData = imageData
                    } catch {
                        print("❌ Fehler beim Laden des Bildes: \(error)")
                        self.podcastImageData = nil
                    }
                } else {
                    self.podcastImageData = nil
                }

                self.selectedPodcastTitle = podcast.name
            }
        }
    }
}

struct PodcastView: View {
    @ObservedObject var podcastStore: PodcastStore
    @ObservedObject var podcastFetcher: PodcastFetcher
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
                        NavigationLink(destination: PodcastDetailView(podcast: podcast, podcastFetcher: podcastFetcher)) { // ✅ podcastFetcher übergeben 
                            PodcastCardView(podcast: podcast)
                        }
                    }
                }
            }
            .padding()
        }
        .background(ScreenPainter.backgroundColor.edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $showAddPodcastDialog) {
            PodcastAddView(showAddPodcastDialog: $showAddPodcastDialog, podcastFetcher: podcastFetcher)
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
                if let artworkPath = podcast.artworkFilePath,
                   let imageData = try? Data(contentsOf: URL(fileURLWithPath: artworkPath)),
                   let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .cornerRadius(10)
                } else {
                    Image(systemName: "mic.fill") // Fallback-Icon
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

    
    
func radioView(radioFetcher: RadioFetcher, showAddRadioDialog: Binding<Bool>, currentRadio: Binding<Radio?>, currentRadioID: Binding<String?>) -> some View {
    
    return ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
            Button(action: { showAddRadioDialog.wrappedValue = true }) {
                VStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    Text("Neuen Sender hinzufügen")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .frame(height: 200)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
            }

            ForEach(radioFetcher.radios, id: \.id) { radio in
                NavigationLink(
                    destination: RadioDetailView(radio: radio),
                    tag: radio.id,
                    selection: currentRadioID // ✅ Übergebene Variable verwenden
                ) {
                    VStack {
                        if let artworkPath = radio.artworkFilePath,
                           let imageData = try? Data(contentsOf: URL(fileURLWithPath: artworkPath)),
                           let image = UIImage(data: imageData) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .cornerRadius(10)
                        } else {
                            Image(systemName: "antenna.radiowaves.left.and.right") // Fallback-Icon
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.gray)
                        }

                        Text(radio.name)
                            .font(.headline)
                            .padding(.top, 5)
                    }
                    .frame(height: 100)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .onTapGesture {
                            handleRadioTap(radio, currentRadio: currentRadio, currentRadioID: currentRadioID)
                        
                    }
                }
            }
                               }
                               .padding()
                           }
                           .onAppear {
                               Task {
                                   await radioFetcher.fetchRadios()
                               }
                           }
                           .sheet(isPresented: showAddRadioDialog) {
                               RadioAddView(showAddRadioDialog: showAddRadioDialog, radioFetcher: radioFetcher)
                           }
                       }

func handleRadioTap(_ radio: Radio, currentRadio: Binding<Radio?>, currentRadioID: Binding<String?>) {
    Task {
        currentRadio.wrappedValue = radio
        currentRadioID.wrappedValue = radio.id
        RadioPlayer.shared.play(radio: radio)
    }
}

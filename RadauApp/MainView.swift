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

                        // Alle UI-Views werden jetzt von `ScreenPainter` übernommen
                        if selectedTab == 0 {
                            ScreenPainter.musicView(playlistFetcher: playlistFetcher, miniPlayerManager: miniPlayerManager)
                        } else if selectedTab == 1 {
                            ScreenPainter.podcastView(podcastStore: podcastStore, podcastFetcher: podcastFetcher, showAddPodcastDialog: $showAddPodcastDialog)
                        } else {
                            ScreenPainter.radioView(radioFetcher: radioFetcher, showAddRadioDialog: $showAddRadioDialog, currentRadio: $currentRadio, currentRadioID: $currentRadioID)
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Deine RadauApp")
                                .font(ScreenPainter.titleFont)
                                .foregroundColor(ScreenPainter.textColor)
                        }
                    }
                    .background(ScreenPainter.backgroundColor.edgesIgnoringSafeArea(.all))
                }

                // MiniPlayer wird ebenfalls von `ScreenPainter` verwaltet
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
}

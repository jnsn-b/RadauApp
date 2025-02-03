import SwiftUI
import UIKit
import Foundation
import MediaPlayer

struct MainView: View {
    @State private var selectedTab: Int = 0
    @StateObject private var authChecker = AuthorizationChecker()
    @StateObject private var podcastFetcher = PodcastFetcher()
    @StateObject private var playlistFetcher = PlaylistFetcher()
    @StateObject private var podcastStore = PodcastStore()
    @StateObject private var radioFetcher = RadioFetcher()
  
    @EnvironmentObject var audioPlayer: AudioPlayer
    @EnvironmentObject var playerUI: PlayerUIState

    @State private var showAddPodcastDialog = false

    // ✅ Fehlende State-Variablen für radioView()
    @State private var showAddRadioDialog = false
    @State private var currentRadio: Radio?
    @State private var currentRadioID: String?

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

                        // ✅ Alle UI-Views jetzt mit AudioPlayer
                        if selectedTab == 0 {
                            ScreenPainter.musicView(playlistFetcher: playlistFetcher, audioPlayer: audioPlayer)
                        } else if selectedTab == 1 {
                            ScreenPainter.podcastView(podcastStore: podcastStore, podcastFetcher: podcastFetcher, showAddPodcastDialog: $showAddPodcastDialog)
                        } else {
                            ScreenPainter.radioView(
                                radioFetcher: radioFetcher, showAddRadioDialog: $showAddRadioDialog, currentRadio: $currentRadio, currentRadioID: $currentRadioID, audioPlayer: audioPlayer)
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

                // ✅ MiniPlayer erscheint automatisch, wenn Audio läuft
            if playerUI.showPlayer || audioPlayer.isPlaying {
                PlayerView()
                    .environmentObject(audioPlayer)
                    .environmentObject(playerUI)
                    .edgesIgnoringSafeArea(.bottom)
                
        
                }
            }
            .background(ScreenPainter.backgroundColor.edgesIgnoringSafeArea(.all))
            .onAppear {
                DispatchQueue.main.async {
                    authChecker.checkAppleMusicAuthorization()
                }
            }
        }
    }
}

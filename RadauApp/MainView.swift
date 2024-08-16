import SwiftUI

struct MainView: View {
    @StateObject private var authChecker = AuthorizationChecker()
    @StateObject private var playlistFetcher = PlaylistFetcher()
    @ObservedObject var miniPlayerManager = ScreenPainter.miniPlayerManager

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                NavigationView {
                    VStack {
                        if authChecker.isAuthorized && authChecker.isMusicKitAuthorized {
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
                        } else if authChecker.isAuthorized {
                            Text("Zugriff auf Apple Music ist autorisiert, aber nicht auf MusicKit.")
                        } else {
                            Text("Zugriff auf Apple Music ist nicht autorisiert.")
                        }
                    }
                    .navigationTitle("Deine RadauAPP")
                    .background(ScreenPainter.backgroundColor.edgesIgnoringSafeArea(.all)) // Hintergrundfarbe auf NavigationView anwenden
                }

                ScreenPainter.renderMiniPlayer()
            }
            .background(ScreenPainter.backgroundColor.edgesIgnoringSafeArea(.all)) // Hintergrundfarbe auf den gesamten ZStack anwenden
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

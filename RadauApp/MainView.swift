import SwiftUI
import UIKit

// Hauptansicht der App, die den Inhalt der App darstellt
struct MainView: View {
    // Verwendung von @StateObject für die Verwaltung des Zustands der Autorisierung und des Playlist-Fetchers
    @StateObject private var authChecker = AuthorizationChecker()
    @StateObject private var playlistFetcher = PlaylistFetcher()
    @ObservedObject var miniPlayerManager = ScreenPainter.miniPlayerManager

    // Definierung eines flexiblen Grid-Layouts mit zwei Spalten und einem Abstand von 16 Punkten
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    // Methode zur Initialisierung einer benutzerdefinierten Schriftart
    func loadCustomFont(name: String, size: CGFloat) -> Font {
        if let uiFont = UIFont(name: name, size: size) {
            return Font(uiFont)
        } else {
            // Fallback auf die Systemschriftart, falls die benutzerdefinierte Schriftart nicht geladen werden kann
            return Font.system(size: size)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                NavigationView {
                    VStack {
                        // Bedingte Anzeige des Inhalts basierend auf den Autorisierungszuständen
                        if authChecker.isAuthorized && authChecker.isMusicKitAuthorized {
                            ScrollView {
                                LazyVGrid(columns: columns, spacing: 20) {
                                    // Anzeigen der Playlists in einem Gitterlayout
                                    ForEach(playlistFetcher.playlists, id: \.persistentID) { playlist in
                                        ScreenPainter.playlistCardView(for: playlist)
                                            .frame(height: 180)
                                            .onTapGesture {
                                                // Setzt die Warteschlange und spielt den ersten Titel ab, wenn auf eine Playlist geklickt wird
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
                            // Startet das Abrufen der Playlists, sobald die Ansicht erscheint
                            .onAppear {
                                playlistFetcher.fetchPlaylists()
                            }
                        } else if authChecker.isAuthorized {
                            // Nachricht, falls nur Apple Music autorisiert ist
                            Text("Zugriff auf Apple Music ist autorisiert, aber nicht auf MusicKit.")
                        } else {
                            // Nachricht, falls keine Autorisierung vorhanden ist
                            Text("Zugriff auf Apple Music ist nicht autorisiert.")
                        }
                    }
                    // Verhindert die Anzeige eines großen Titels in der Navigationsleiste
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        // Anpassung des Titels in der Navigationsleiste mit einer benutzerdefinierten Schriftart und Farbe
                        ToolbarItem(placement: .principal) {
                            Text("Deine RadauApp")
                                .font(loadCustomFont(name: "KristenITC-Regular", size: 24))
                                .foregroundColor(ScreenPainter.textColor)
                        }
                    }
                    // Hintergrundfarbe auf die gesamte NavigationView anwenden
                    .background(ScreenPainter.backgroundColor.edgesIgnoringSafeArea(.all))
                }

                // Mini-Player anzeigen, der durch ScreenPainter gerendert wird
                ScreenPainter.renderMiniPlayer()
            }
            // Hintergrundfarbe auf den gesamten ZStack anwenden
            .background(ScreenPainter.backgroundColor.edgesIgnoringSafeArea(.all))
            .onAppear {
                // Prüfen der Apple Music Autorisierung beim Erscheinen der Ansicht
                DispatchQueue.main.async {
                    authChecker.checkAppleMusicAuthorization()
                }
            }
            // Präsentiert den MusicPlayerView als modale Ansicht, wenn miniPlayerManager.showPlayer aktiviert ist
            .sheet(isPresented: $miniPlayerManager.showPlayer) {
                MusicPlayerView(musicPlayer: miniPlayerManager.musicPlayer, showMiniPlayer: $miniPlayerManager.showMiniPlayer)
            }
        }
    }
}

import SwiftUI
import MediaPlayer
import MusicKit

class MiniPlayerManager: ObservableObject {
    @Published var showMiniPlayer: Bool = false
    @Published var showPlayer: Bool = false
    var musicPlayer = MusicPlayer()
    
    func minimizePlayer() {
        withAnimation {
            showMiniPlayer = true
            showPlayer = false
        }
    }
    
    func maximizePlayer() {
        withAnimation {
            showMiniPlayer = false
            showPlayer = true
        }
    }
    
    func togglePlayer() {
        if showPlayer {
            minimizePlayer()
        } else {
            maximizePlayer()
        }
    }
}

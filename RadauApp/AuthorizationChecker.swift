
import Foundation
import MediaPlayer
import MusicKit

class AuthorizationChecker: ObservableObject {
    @Published var isAuthorized: Bool = false
    @Published var isMusicKitAuthorized: Bool = false
    
    func checkAppleMusicAuthorization() {
        let status = MPMediaLibrary.authorizationStatus()
        if status == .authorized {
            isAuthorized = true
            checkMusicKitAuthorization()
        } else {
            requestAppleMusicAccess()
        }
    }
    
    private func requestAppleMusicAccess() {
        MPMediaLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                if status == .authorized {
                    self.isAuthorized = true
                    self.checkMusicKitAuthorization()
                } else {
                    self.isAuthorized = false
                    self.handleAuthorizationDenied()
                }
            }
        }
    }
    
    private func checkMusicKitAuthorization() {
        let status = MusicAuthorization.currentStatus
        if status == .authorized {
            DispatchQueue.main.async {
                self.isMusicKitAuthorized = true
            }
        } else {
            requestMusicKitAccess()
        }
    }
    
    private func requestMusicKitAccess() {
        Task {
            let status = await MusicAuthorization.request()
            DispatchQueue.main.async {
                if status == .authorized {
                    self.isMusicKitAuthorized = true
                } else {
                    self.isMusicKitAuthorized = false
                    self.handleMusicKitAuthorizationDenied()
                }
            }
        }
    }
    
    private func handleAuthorizationDenied() {
        // Hier können Sie eine Fehlermeldung anzeigen oder andere Maßnahmen ergreifen.
        print("Zugriff auf Apple Music wurde verweigert.")
    }
    
    private func handleMusicKitAuthorizationDenied() {
        // Hier können Sie eine Fehlermeldung anzeigen oder andere Maßnahmen ergreifen.
        print("Zugriff auf MusicKit wurde verweigert.")
    }
}

import Foundation
import MediaPlayer
import MusicKit

// Klasse zur Überprüfung der Apple Music- und MusicKit-Autorisierung
class AuthorizationChecker: ObservableObject {
    // Veröffentlichte Variablen zur Überwachung der Autorisierungszustände
    @Published var isAuthorized: Bool = false
    @Published var isMusicKitAuthorized: Bool = false
    
    // Methode zur Überprüfung der Apple Music-Autorisierung
    func checkAppleMusicAuthorization() {
        let status = MPMediaLibrary.authorizationStatus()
        if status == .authorized {
            isAuthorized = true
            checkMusicKitAuthorization()
        } else {
            requestAppleMusicAccess()
        }
    }
    
    // Private Methode zur Anforderung des Apple Music-Zugriffs
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
    
    // Private Methode zur Überprüfung der MusicKit-Autorisierung
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
    
    // Private Methode zur Anforderung des MusicKit-Zugriffs
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
    
    // Private Methode, die ausgeführt wird, wenn die Apple Music-Autorisierung verweigert wird
    private func handleAuthorizationDenied() {
        // Hier können Sie eine Fehlermeldung anzeigen oder andere Maßnahmen ergreifen.
        // Zum Beispiel könnte eine UI-Komponente benachrichtigt werden, dass die Autorisierung fehlgeschlagen ist.
    }
    
    // Private Methode, die ausgeführt wird, wenn die MusicKit-Autorisierung verweigert wird
    private func handleMusicKitAuthorizationDenied() {
        // Hier können Sie eine Fehlermeldung anzeigen oder andere Maßnahmen ergreifen.
        // Zum Beispiel könnte eine UI-Komponente benachrichtigt werden, dass die Autorisierung fehlgeschlagen ist.
    }
}

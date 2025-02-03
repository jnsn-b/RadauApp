import SwiftUI

// Hauptanwendungseintragspunkt mit dem @main-Attribut
@main
struct RadauApp: App {
    @StateObject private var audioPlayer = AudioPlayer()
    @StateObject var playerUI = PlayerUIState()
    // Initialisierer für die App, um das Erscheinungsbild der Navigationsleiste zu konfigurieren.
    init() {
        // Erstellung einer neuen UINavigationBarAppearance-Instanz
        let appearance = UINavigationBarAppearance()
        
        // Konfigurieren der Navigationsleiste mit einem undurchsichtigen Hintergrund
        appearance.configureWithOpaqueBackground()
        
        // Setzen der Hintergrundfarbe der Navigationsleiste auf die primäre Farbe der App
        appearance.backgroundColor = UIColor(ScreenPainter.primaryColor)
        
        // Festlegen der Textfarbe für den Titel in der Navigationsleiste auf Weiß
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        // Festlegen der Textfarbe für große Titel in der Navigationsleiste auf Weiß
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        // Anwenden des Erscheinungsbilds auf verschiedene Zustände der Navigationsleiste
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Festlegen der Farbe für den Zurück-Pfeil und den Text in der Navigationsleiste auf Weiß
        UINavigationBar.appearance().tintColor = .white
        
    
    }

    // Hauptinhalt der App
    var body: some Scene {
        WindowGroup {
            // Einstiegspunkt der App, hier wird die MainView angezeigt
            MainView()
                .environmentObject(audioPlayer)
                .environmentObject(playerUI)
            
            
        }
    }
}

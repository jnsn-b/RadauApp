import SwiftUI

@main
struct RadauApp: App {
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(ScreenPainter.primaryColor)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = .white // Setzt die Farbe des Zurück-Pfeils und des Textes auf Weiß
        
    }

    var body: some Scene {
        WindowGroup {
            MainView() // oder der Start-View deiner App
        }
    }
}

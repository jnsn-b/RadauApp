/*
 
 Reaktivität: Als ObservableObject ermöglicht der PodcastStore automatische UI-Updates in SwiftUI, wenn sich die Podcast-Liste ändert.
 Zwischenspeicher: Er hält eine in-memory Liste der Podcasts, was schnellere Zugriffe ermöglicht als ständiges Lesen von der Festplatte.
 Abstraktion: Er bietet eine einfachere Schnittstelle für UI-Komponenten und kapselt die Komplexität des PodcastInfoHandlers.
 Asynchrone Verarbeitung: Der Store kann asynchrone Operationen des PodcastInfoHandlers in einer für SwiftUI geeigneten Weise verwalten.
 Erweiterbarkeit: Zukünftige Funktionen wie Caching oder zusätzliche Podcast-Verwaltungsfunktionen können hier leicht implementiert werden.
 Der PodcastStore fungiert somit als wichtige Vermittlerschicht zwischen der Datenpersistenz (PodcastInfoHandler) und der Benutzeroberfläche, was die Architektur der App verbessert.
 */

 import SwiftUI

class PodcastStore: ObservableObject {
    @Published var podcasts: [PodcastFetcher.Podcast] = []
    
    func loadPodcasts() {
        Task {
            let loadedPodcasts = await PodcastInfoHandler.getPodcasts()
            DispatchQueue.main.async {
                self.podcasts = loadedPodcasts
            }
        }
    }
    
    func addPodcast(_ podcast: PodcastFetcher.Podcast) {
        DispatchQueue.main.async {
            self.podcasts.append(podcast)
        }
    }
}

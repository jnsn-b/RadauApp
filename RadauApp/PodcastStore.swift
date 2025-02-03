/*
 
 Reaktivität: Als ObservableObject ermöglicht der PodcastStore automatische UI-Updates in SwiftUI, wenn sich die Podcast-Liste ändert.
 Zwischenspeicher: Er hält eine in-memory Liste der Podcasts, was schnellere Zugriffe ermöglicht als ständiges Lesen von der Festplatte.
 Abstraktion: Er bietet eine einfachere Schnittstelle für UI-Komponenten und kapselt die Komplexität des PodcastInfoHandlers.
 Asynchrone Verarbeitung: Der Store kann asynchrone Operationen des PodcastInfoHandlers in einer für SwiftUI geeigneten Weise verwalten.
 Erweiterbarkeit: Zukünftige Funktionen wie Caching oder zusätzliche Podcast-Verwaltungsfunktionen können hier leicht implementiert werden.
 Der PodcastStore fungiert somit als wichtige Vermittlerschicht zwischen der Datenpersistenz (PodcastInfoHandler) und der Benutzeroberfläche, was die Architektur der App verbessert.
 */

import Foundation

@MainActor
class PodcastStore: ObservableObject {
    @Published var podcasts: [PodcastFetcher.Podcast] = []
    @Published var loadingPodcasts: Set<String> = []
    private var isLoadingPodcasts = false  // 🛑 Neues Flag

    func loadPodcasts() {
        guard !isLoadingPodcasts else {
            print("⚠️ `loadPodcasts()` wurde bereits gestartet, überspringe...")
            return
        }
        
        isLoadingPodcasts = true
        print("📢 `loadPodcasts()` startet...")
        
        Task {
            let savedPodcasts = await PodcastInfoHandler.getPodcasts()
            DispatchQueue.main.async {
                self.podcasts = savedPodcasts
                self.isLoadingPodcasts = false  // ✅ Flag zurücksetzen
                print("✅ Podcasts erfolgreich geladen.")
            }
        }
    }
    
    func loadEpisodes() async {
        print("🔄 Starte Episoden-Ladevorgang...")

        for index in podcasts.indices {
            let podcast = podcasts[index]

            if loadingPodcasts.contains(podcast.id) {
                print("⚠️ `\(podcast.name)` wird bereits geladen. Überspringe...")
                continue
            }

            loadingPodcasts.insert(podcast.id)

            let fetchedEpisodes = await PodcastFetcher().fetchEpisodes(from: podcast.feedURL, podcast: podcast)

            DispatchQueue.main.async {
                if fetchedEpisodes.isEmpty {
                    print("⚠️ Keine Episoden für '\(podcast.name)' gefunden.")
                } else {
                    print("✅ \(fetchedEpisodes.count) Episoden für '\(podcast.name)' gespeichert!")

                    // 🛠 **Batch-Update: Episoden in Blöcken speichern**
                    let chunkSize = 50  // 🛠 **Max. 50 Episoden pro Batch**
                    var currentEpisodes = [PodcastFetcher.PodcastEpisode]()

                    for (i, episode) in fetchedEpisodes.enumerated() {
                        currentEpisodes.append(episode)

                        // ✅ UI-Update nach jedem Batch (verhindert UI-Freeze)
                        if i % chunkSize == 0 || i == fetchedEpisodes.count - 1 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                self.podcasts[index] = PodcastFetcher.Podcast(
                                    id: podcast.id,
                                    name: podcast.name,
                                    feedURL: podcast.feedURL,
                                    artworkFilePath: podcast.artworkFilePath,
                                    episodes: currentEpisodes
                                )
                                print("📌 `PodcastStore.podcasts` Batch gespeichert: \(currentEpisodes.count) Episoden.")
                            }
                        }
                    }
                }
                self.loadingPodcasts.remove(podcast.id)
            }
        }
    }
}

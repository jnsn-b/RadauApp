/*import SwiftUI

struct AddPodcastView: View {
    @Binding var showAddPodcastDialog: Bool
    @State private var feedURL: String = ""

    var body: some View {
        VStack {
            Text("Geben Sie die Podcast-Feed-URL ein:")
                .font(.headline)
                .padding()

            TextField("Feed-URL", text: $feedURL)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            HStack {
                Button("Abbrechen") {
                    showAddPodcastDialog = false
                }
                .padding()

                Button("Hinzufügen") {

                    // Speichern des Podcasts über den PodcastInfoHandler
                    PodcastInfoHandler.savePodcast(feedURL: feedURL)
                    
                    showAddPodcastDialog = false
                }
                .padding()
            }
        }
        .padding()
    }
}
*/
import SwiftUI

struct PodcastAddView: View {
    @Binding var showAddPodcastDialog: Bool
    @ObservedObject var podcastFetcher: PodcastFetcher
    @State private var searchQuery: String = ""
    @State private var searchResults: [PodcastFetcher.Podcast] = []
    @State private var selectedPodcast: PodcastFetcher.Podcast?

    var body: some View {
        VStack {
            Text("Neuen Podcast hinzufügen")
                .font(.headline)
                .padding()

            // 🔍 Podcast-Suchfeld
            TextField("Podcast-Name eingeben", text: $searchQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onSubmit {
                    Task {
                        searchResults = await PodcastFetcher.PodcastSearchAPI.searchPodcasts(by: searchQuery)
                    }
                }

            // 📜 Liste mit Suchergebnissen
            List(searchResults, id: \.id) { podcast in
                HStack {
                    AsyncImage(url: URL(string: podcast.artworkFilePath ?? "")) { image in
                        image.resizable().frame(width: 50, height: 50).cornerRadius(8)
                    } placeholder: {
                        Image(systemName: "mic.fill").resizable().frame(width: 50, height: 50).foregroundColor(.gray)
                    }

                    VStack(alignment: .leading) {
                        Text(podcast.name).font(.headline)
                        Text(podcast.feedURL).font(.subheadline).foregroundColor(.gray)
                    }
                }
                .onTapGesture {
                    selectedPodcast = podcast
                }
            }

            // ✅ Hinzufügen-Button
            if let selectedPodcast {
                Button("Hinzufügen: \(selectedPodcast.name)") {
                    saveSelectedPodcast()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            Button("Abbrechen") {
                showAddPodcastDialog = false
            }
            .padding()
        }
        .padding()
    }

    private func saveSelectedPodcast() {
        guard let selectedPodcast else { return }

        Task {
            await PodcastInfoHandler.savePodcast( // 🔥 `try` entfernt, da kein Fehler geworfen wird
                name: selectedPodcast.name,
                feedURL: selectedPodcast.feedURL,
                artworkURL: selectedPodcast.artworkFilePath
            )

            let episodes = await podcastFetcher.fetchEpisodes(from: selectedPodcast.feedURL, podcast: selectedPodcast)

            DispatchQueue.main.async {
                podcastFetcher.podcasts.append(selectedPodcast)
                showAddPodcastDialog = false
            }
        }
    }
}

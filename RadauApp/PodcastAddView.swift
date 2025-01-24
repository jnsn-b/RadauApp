import SwiftUI

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

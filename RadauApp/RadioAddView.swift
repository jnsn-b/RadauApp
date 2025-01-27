import SwiftUI



import SwiftUI

struct RadioAddView: View {
    @Binding var showAddRadioDialog: Bool
    @ObservedObject var radioFetcher: RadioFetcher
    @State private var searchQuery: String = ""
    @State private var searchResults: [Radio] = []
    @State private var selectedRadio: Radio?

    var body: some View {
        VStack {
            Text("Neuen Radiosender hinzufügen")
                .font(.headline)
                .padding()

            // Suchfeld für Radiosender
            TextField("Sendername eingeben", text: $searchQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onSubmit {
                    Task {
                        await searchStations()
                    }
                }

            // Zeige Suchergebnisse an
            List(searchResults, id: \.id) { radio in
                HStack {
                    if let artworkData = radio.artworkData, let uiImage = UIImage(data: artworkData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .frame(width: 50, height: 50)
                            .cornerRadius(8)
                    } else {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)
                    }
                    VStack(alignment: .leading) {
                        Text(radio.name)
                            .font(.headline)
                        Text(radio.streamURL)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .onTapGesture {
                    selectedRadio = radio
                }
            }

            // Bestätigungsbutton, wenn ein Sender ausgewählt wurde
            if let selectedRadio {
                Button("Hinzufügen: \(selectedRadio.name)") {
                    saveSelectedRadio()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            Button("Abbrechen") {
                showAddRadioDialog = false
            }
            .padding()
        }
        .padding()
    }

    // API-Abfrage für die Radiosender-Suche
    private func searchStations() async {
        searchResults = await RadioInfoHandler.searchRadios(by: searchQuery)
    }

    // Speichert den ausgewählten Radiosender
    private func saveSelectedRadio() {
        guard let selectedRadio else { return }

        Task {
            let radioID = UUID().uuidString
            let artworkFileName = "\(radioID).jpg"  // ✅ Speichere nur den Dateinamen
            let localArtworkPath = RadioInfoHandler.getPublicRadiosDirectory().appendingPathComponent(artworkFileName)

            if let artworkData = selectedRadio.artworkData {
                do {
                    try artworkData.write(to: localArtworkPath)
                    print("✅ Radio-Icon gespeichert unter: \(localArtworkPath.path)")
                } catch {
                    print("❌ Fehler beim Speichern des Radio-Icons: \(error)")
                }
            } else {
                print("⚠️ Kein Artwork für \(selectedRadio.name) vorhanden.")
            }

            // ✅ Überprüfe, ob der Parameter `artworkFileName` oder `artworkURL` heißen muss
            await RadioInfoHandler.saveRadio(
                id: radioID,
                name: selectedRadio.name,
                streamURL: selectedRadio.streamURL,
                artworkURL: selectedRadio.artworkData != nil ? artworkFileName : nil // ✅ Korrigiert
            )

            // ✅ UI-Update auf dem Main-Thread
            await MainActor.run {
                showAddRadioDialog = false
                Task {
                    await radioFetcher.fetchRadios()
                }
            }
        }
    }
}

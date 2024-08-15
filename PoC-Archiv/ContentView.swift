import SwiftUI
import MusicKit
import MediaPlayer

struct ContentView: View {
    @State private var isAuthorized = false
    @State private var playlists: [MPMediaPlaylist] = []
    @State private var selectedPlaylists: Set<MPMediaEntityPersistentID> = Set<MPMediaEntityPersistentID>()
    @State private var selectedTrack: MusicItemID? = nil
    @State private var musicPlayer = ApplicationMusicPlayer.shared

    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(filteredPlaylists, id: \.id) { playlist in
                        PlaylistItemView(playlist: playlist, musicPlayer: musicPlayer)
                    }
                }
                .padding()
                .onAppear {
                    if isAuthorized {
                        loadPlaylists()
                    }
                }
            }
            .navigationTitle("RadauApp")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ParentsView(playlists: $playlists, selectedPlaylists: $selectedPlaylists)) {
                        Image(systemName: "gearshape.fill")
                            .imageScale(.large)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .onAppear {
            checkAppleMusicAuthorization()
        }
    }

    // Add this computed property to your ContentView
    private var filteredPlaylists: [MPMediaPlaylist] {
        playlists.filter { selectedPlaylists.contains($0.persistentID) }
    }

    func checkAppleMusicAuthorization() {
           let status = MPMediaLibrary.authorizationStatus()
           if status == .authorized {
               isAuthorized = true
               loadPlaylists()
           } else if status == .notDetermined {
               requestAppleMusicAccess()
           } else {
               print("Access denied or restricted")
           }
       }

       func requestAppleMusicAccess() {
           MPMediaLibrary.requestAuthorization { status in
               DispatchQueue.main.async {
                   if status == .authorized {
                       isAuthorized = true
                       loadPlaylists()
                   } else {
                       isAuthorized = false
                   }
               }
           }
       }

    func loadPlaylists() {
            let query = MPMediaQuery.playlists()
            if let playlists = query.collections as? [MPMediaPlaylist] {
                self.playlists = playlists
                print("Loaded \(playlists.count) playlists")
                if selectedPlaylists.isEmpty {
                    self.selectedPlaylists = Set(playlists.map { $0.persistentID })
                    print("Selected \(selectedPlaylists.count) playlists by default")
                }
            } else {
                print("No playlists found")
            }
        }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

import SwiftUI

import SwiftUI

struct RadioDetailView: View {
    let radio: Radio
    @ObservedObject var radioPlayer = RadioPlayer()

    var body: some View {
        VStack {
            if let artworkData = radio.artworkData, let uiImage = UIImage(data: artworkData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .cornerRadius(10)
            } else if let artworkFilePath = radio.artworkFilePath, FileManager.default.fileExists(atPath: artworkFilePath),
                      let imageData = try? Data(contentsOf: URL(fileURLWithPath: artworkFilePath)),
                      let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .cornerRadius(10)
            } else {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
            }

            Text(radio.name)
                .font(.title)
                .padding()

            Button(action: {
                if radioPlayer.isPlaying {
                    radioPlayer.stop()
                } else {
                    radioPlayer.play(radio: radio)
                }
            }) {
                Image(systemName: radioPlayer.isPlaying ? "stop.fill" : "play.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
            }
        }
        .padding()
    }
}

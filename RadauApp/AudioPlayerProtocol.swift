import Foundation
/// Gemeinsames Protokoll für Apple Music und AVPlayer-basierte Audioquellen
protocol AudioPlayerProtocol: ObservableObject {


    func play()
    func pause()
    func stop()
    func next()
    func previous()
}

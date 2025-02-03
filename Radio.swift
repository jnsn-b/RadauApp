import Foundation

struct Radio: Identifiable {
    let id: String
    let name: String
    let streamURL: String
    let artworkData: Data?
    let artworkFilePath: String? 
}

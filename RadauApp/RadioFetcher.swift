import Foundation
import UIKit

class RadioFetcher: ObservableObject {
    @Published var radios: [Radio] = []

    func fetchRadios() async {
        let loadedRadios = await RadioInfoHandler.getRadios()
        DispatchQueue.main.async {
            self.radios = loadedRadios
        }
    }
}

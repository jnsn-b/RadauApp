import SwiftUI
import PhotosUI

// Eine SwiftUI View, die einen UIKit PHPickerViewController verwendet, um Bilder aus der Fotobibliothek auszuwählen
struct PhotoPickerView: UIViewControllerRepresentable {
    
    // Bindung an das Präsentations-Modus-Environment, um die View nach der Auswahl schließen zu können
    @Environment(\.presentationMode) var presentationMode
    
    // Gebundenes UIImage-Objekt, um das ausgewählte Bild an die aufrufende View zurückzugeben
    @Binding var selectedImage: UIImage?
    
    // Eine eindeutige ID, die verwendet wird, um das Bild der entsprechenden Playlist zuzuordnen
    var playlistID: UInt64

    // Erstellt den PHPickerViewController, der es dem Benutzer ermöglicht, Bilder aus der Fotobibliothek auszuwählen
    func makeUIViewController(context: Context) -> PHPickerViewController {
        // Konfiguration des Pickers, um nur Bilder anzuzeigen und eine Auswahl zu ermöglichen
        var configuration = PHPickerConfiguration()
        configuration.filter = .images  // Zeigt nur Bilder an
        configuration.selectionLimit = 1  // Begrenzt die Auswahl auf ein Bild

        // Erstellt eine Instanz des PHPickerViewController mit der Konfiguration
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator  // Setzt den Coordinator als Delegate des Pickers
        return picker
    }

    // Wird verwendet, um den PHPickerViewController zu aktualisieren (hier nicht benötigt)
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    // Erstellt den Coordinator, der als PHPickerViewControllerDelegate fungiert und die Bildauswahl verarbeitet
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // Der Coordinator fungiert als Delegate und verwaltet die Bildauswahl
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: PhotoPickerView  // Referenz auf die übergeordnete PhotoPickerView

        // Initialisiert den Coordinator mit einer Referenz auf die übergeordnete PhotoPickerView
        init(_ parent: PhotoPickerView) {
            self.parent = parent
        }

        // Wird aufgerufen, wenn der Benutzer ein Bild ausgewählt oder den Picker abgebrochen hat
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // Schließt den Picker nach der Auswahl oder dem Abbruch
            picker.dismiss(animated: true, completion: nil)

            // Stellt sicher, dass ein Ergebnis vorhanden ist und ruft den ersten ItemProvider ab
            guard let provider = results.first?.itemProvider else { return }

            // Überprüft, ob der ItemProvider ein UIImage laden kann
            if provider.canLoadObject(ofClass: UIImage.self) {
                // Lädt das Bild asynchron und speichert es in der gebundenen Variable
                provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                    DispatchQueue.main.async {
                        if let uiImage = image as? UIImage {
                            // Weist das ausgewählte Bild der gebundenen Variable zu
                            self?.parent.selectedImage = uiImage
                            // Speichert das Bild für die Playlist mit der entsprechenden ID
                            PlaylistImageHandler.shared.saveImage(uiImage, for: self?.parent.playlistID ?? 0)
                            
                        }
                    }
                }
            }

            // Schließt die PhotoPickerView-View
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

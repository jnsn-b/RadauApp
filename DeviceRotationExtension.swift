import SwiftUI

// Erweiterung für View, um auf Rotationsänderungen des Geräts zu reagieren
extension View {
    // Methode, die einen View-Modifier hinzufügt, um auf Änderungen der Geräteausrichtung zu reagieren
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}

// ViewModifier, der auf Geräteorientierungsänderungen reagiert und eine Aktion ausführt
struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void  // Die Aktion, die bei einer Änderung ausgeführt wird
    
    func body(content: Content) -> some View {
        content
            .onAppear()  // Sicherstellen, dass der Modifier aktiv ist, wenn die View erscheint
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                // Wenn eine Rotationsänderung erkannt wird, führe die Aktion mit der aktuellen Ausrichtung aus
                action(UIDevice.current.orientation)
            }
    }
}

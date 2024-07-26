import SwiftUI

struct NFCViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> NFCViewController {
            return NFCViewController()
        }

    func updateUIViewController(_ uiViewController: NFCViewController, context: Context) {
        // Hier können Sie den ViewController aktualisieren, falls erforderlich.
    }
}


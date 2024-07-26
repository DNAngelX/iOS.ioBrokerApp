import UIKit
import CoreNFC

class NFCReaderViewController: UIViewController, NFCNDEFReaderSessionDelegate {
    private var nfcSession: NFCNDEFReaderSession?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
    }

    private func setupUI() {
        let startReadingButton = UIButton(type: .system)
        startReadingButton.setTitle("Start NFC Lesen", for: .normal)
        startReadingButton.addTarget(self, action: #selector(startReadingTapped), for: .touchUpInside)

        startReadingButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(startReadingButton)
        NSLayoutConstraint.activate([
            startReadingButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startReadingButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func startReadingTapped() {
        guard NFCNDEFReaderSession.readingAvailable else {
            let alertController = UIAlertController(title: "Fehler", message: "NFC Lesen ist nicht verfügbar", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
            return
        }
        nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        nfcSession?.begin()
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        print("NFC Session invalidiert: \(error.localizedDescription)")
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        guard let ndefMessage = messages.first else { return }
        let record = ndefMessage.records.first
        let payload = record?.payload
        let tagId = "someTagId" // Hier müsste der richtige Tag ID ausgelesen werden
        let name = "someName" // Hier müsste der richtige Name ausgelesen werden
        DispatchQueue.main.async {
            let nfcTagDetailsVC = NFCTagDetailsViewController(tagId: tagId, name: name)
            self.present(nfcTagDetailsVC, animated: true, completion: nil)
        }
    }
}

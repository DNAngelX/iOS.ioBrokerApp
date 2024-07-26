import UIKit
import CoreNFC

class NFCViewController: UIViewController, NFCNDEFReaderSessionDelegate {
    private var nfcSession: NFCNDEFReaderSession?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
    }

    private func setupUI() {
        // Bubble explanation
        let bubbleView = UIView()
        bubbleView.backgroundColor = .systemBlue
        bubbleView.layer.cornerRadius = 15
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        
        let explanationLabel = UILabel()
        explanationLabel.text = "Erklärung: NFC Tags können verwendet werden, um Aktionen im IoBroker auszulösen, wie z.B. Türen öffnen, Licht an/aus, usw."
        explanationLabel.textColor = .white
        explanationLabel.numberOfLines = 0
        explanationLabel.textAlignment = .center
        explanationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        bubbleView.addSubview(explanationLabel)
        view.addSubview(bubbleView)
        
        // Buttons
        let readTagsButton = UIButton(type: .system)
        readTagsButton.setTitle("Tags Lesen", for: .normal)
        readTagsButton.addTarget(self, action: #selector(readTagsTapped), for: .touchUpInside)
        
        let writeTagsButton = UIButton(type: .system)
        writeTagsButton.setTitle("Tags Schreiben", for: .normal)
        writeTagsButton.addTarget(self, action: #selector(writeTagsTapped), for: .touchUpInside)
        
        let stackView = UIStackView(arrangedSubviews: [readTagsButton, writeTagsButton])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            bubbleView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bubbleView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            bubbleView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            
            explanationLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 10),
            explanationLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -10),
            explanationLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            explanationLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),
            
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 40)
        ])
    }

    @objc private func readTagsTapped() {
        startNFCSession()
    }

    @objc private func writeTagsTapped() {
        let actionSheet = UIAlertController(title: "Tags Schreiben", message: "Wählen Sie eine Option", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Automatisch", style: .default, handler: { _ in
            self.presentWriteTagAlert(isAutomatic: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Manuell", style: .default, handler: { _ in
            self.presentWriteTagAlert(isAutomatic: false)
        }))
        actionSheet.addAction(UIAlertAction(title: "Abbrechen", style: .cancel, handler: nil))
        present(actionSheet, animated: true, completion: nil)
    }

    private func presentWriteTagAlert(isAutomatic: Bool) {
        let alert = UIAlertController(title: "Tag Beschreiben", message: "Geben Sie die Informationen ein", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Name"
        }
        if !isAutomatic {
            alert.addTextField { textField in
                textField.placeholder = "Tag ID"
            }
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            let name = alert.textFields?[0].text ?? ""
            let tagId = isAutomatic ? UUID().uuidString : (alert.textFields?[1].text ?? "")
            let nfcWriteVC = NFCWriteViewController(tagId: tagId, name: name)
            self.present(nfcWriteVC, animated: true, completion: nil)
        }))
        present(alert, animated: true, completion: nil)
    }

    private func startNFCSession() {
        guard NFCNDEFReaderSession.readingAvailable else {
            let alertController = UIAlertController(title: "Fehler", message: "NFC Lesen ist nicht verfügbar", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
            return
        }
        nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        nfcSession?.begin()
    }

    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        print("NFC-Lesesession ist aktiv geworden.")
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        print("NFC Session invalidiert: \(error.localizedDescription)")
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        guard let ndefMessage = messages.first else { return }
        let record = ndefMessage.records.first
        let payload = record?.payload

        guard let payloadData = payload else {
            session.invalidate(errorMessage: "Kein IoBroker TAG")
            return
        }

        guard let payloadString = String(data: payloadData, encoding: .utf8), payloadString.contains("iobrokerapp://tag?") else {
            session.invalidate(errorMessage: "Kein IoBroker TAG")
            return
        }

        if let urlComponents = URLComponents(string: payloadString),
           let queryItems = urlComponents.queryItems {
            let tagId = queryItems.first(where: { $0.name == "tagId" })?.value ?? "Unknown"
            let name = queryItems.first(where: { $0.name == "name" })?.value ?? "Unknown"

            IoBrokerAPI.checkTagExists(tagID: tagId) { exists in
                DispatchQueue.main.async {
                    if exists {
                        let nfcTagDetailsVC = NFCTagDetailsViewController(tagId: tagId, name: name)
                        self.present(nfcTagDetailsVC, animated: true, completion: nil)
                    } else {
                        let alertController = UIAlertController(title: "Fehler", message: "Tag existiert nicht im IoBroker", preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alertController, animated: true, completion: nil)
                    }
                }
            }
        } else {
            session.invalidate(errorMessage: "Kein IoBroker TAG")
        }
    }
}

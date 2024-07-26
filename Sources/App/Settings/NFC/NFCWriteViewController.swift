import UIKit
import CoreNFC

class NFCWriteViewController: UIViewController, NFCNDEFReaderSessionDelegate {
    private var nfcSession: NFCNDEFReaderSession?
    private var tagId: String?
    private var name: String?

    init(tagId: String, name: String) {
        self.tagId = tagId
        self.name = name
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        startNFCSessionForWriting()
    }

    private func startNFCSessionForWriting() {
        guard NFCNDEFReaderSession.readingAvailable else {
            let alertController = UIAlertController(title: "Fehler", message: "NFC Schreiben ist nicht verfügbar", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
            return
        }
        nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        nfcSession?.begin()
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        print("NFC Session invalidiert: \(error.localizedDescription)")
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard let name = self.name, let tagId = self.tagId else { return }
        guard let tag = tags.first else { return }

        session.connect(to: tag) { error in
            if let error = error {
                print("Fehler beim Verbinden: \(error.localizedDescription)")
                session.invalidate(errorMessage: "Fehler beim Verbinden mit dem Tag.")
                return
            }

            tag.queryNDEFStatus { ndefStatus, capacity, error in
                if let error = error {
                    print("Fehler beim Abfragen des NDEF-Status: \(error.localizedDescription)")
                    session.invalidate(errorMessage: "Fehler beim Abfragen des NDEF-Status.")
                    return
                }

                if ndefStatus == .readWrite {
                    let ndefMessage = NFCNDEFMessage(records: [NFCNDEFPayload.wellKnownTypeURIPayload(string: "iobrokerapp://tag?name=\(name)&tagId=\(tagId)")!])
                    tag.writeNDEF(ndefMessage) { error in
                        if let error = error {
                            print("Fehler beim Schreiben: \(error.localizedDescription)")
                            session.invalidate(errorMessage: "Fehler beim Schreiben auf den Tag.")
                        } else {
                            print("NFC Tag erfolgreich beschrieben")
                            session.alertMessage = "NFC Tag erfolgreich beschrieben."
                            IoBrokerAPI.createTag(tagID: tagId, name: name) { success in
                                if success {
                                    print("Tag erfolgreich im IoBroker erstellt")
                                } else {
                                    print("Fehler beim Erstellen des Tags im IoBroker")
                                }
                            }
                            session.invalidate()
                        }
                    }
                } else {
                    print("Tag ist nicht beschreibbar oder ist leer")
                    session.invalidate(errorMessage: "Tag ist nicht beschreibbar oder ist leer.")
                }
            }
        }
    }

    // Diese Methode ist notwendig, um das Protokoll NFCNDEFReaderSessionDelegate zu erfüllen.
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        // Implementieren Sie die erforderliche Logik hier, falls notwendig
    }
}

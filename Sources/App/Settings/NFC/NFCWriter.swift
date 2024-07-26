import CoreNFC

class NFCWriter: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
    @Published var tagId: String = UUID().uuidString
    @Published var tagName: String = ""
    @Published var writeStatus: String = ""

    private var session: NFCNDEFReaderSession?

    func beginWriting(tagName: String, completion: @escaping (Bool) -> Void) {
        guard NFCNDEFReaderSession.readingAvailable else {
            writeStatus = "NFC is not available on this device."
            completion(false)
            return
        }

        self.tagName = tagName
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = "Hold your iPhone near the NFC tag to write."
        session?.begin()
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        if let nfcError = error as? NFCReaderError {
            switch nfcError.code {
            case .readerSessionInvalidationErrorUserCanceled:
                writeStatus = "Session canceled by user."
            case .readerSessionInvalidationErrorSessionTimeout:
                writeStatus = "Session timeout."
            default:
                writeStatus = "Session invalidated: \(error.localizedDescription)"
            }
        } else {
            writeStatus = "Session invalidated: \(error.localizedDescription)"
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        // Handle detected tags if necessary
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard let tag = tags.first else { return }

        session.connect(to: tag) { error in
            if let error = error {
                self.writeStatus = "Failed to connect to tag: \(error.localizedDescription)"
                session.invalidate(errorMessage: "Connection error. Please try again.")
                return
            }

            guard let payload = NFCNDEFPayload.wellKnownTypeURIPayload(string: "http://\(self.tagId)&name=\(self.tagName)") else {
                self.writeStatus = "Failed to create NDEF payload."
                session.invalidate(errorMessage: "Payload error. Please try again.")
                return
            }
            let message = NFCNDEFMessage(records: [payload])

            tag.writeNDEF(message) { error in
                if let error = error {
                    self.writeStatus = "Failed to write to tag: \(error.localizedDescription)"
                    session.invalidate(errorMessage: "Write error. Please try again.")
                    completion(false)  // Error, call completion with false
                } else {
                    self.writeStatus = "Successfully wrote to the NFC tag."
                    session.alertMessage = "Successfully wrote to the NFC tag."
                    session.invalidate()
                    DispatchQueue.main.async {
                        NFCManager.shared.presentResultView(tagId: self.tagId, tagName: self.tagName)
                    }
                    completion(true)  // Success, call completion with true
                }
            }
        }
    }
}

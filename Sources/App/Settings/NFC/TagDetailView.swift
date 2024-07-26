import SwiftUI

struct TagDetailView: View {
    let tagID: String

    var body: some View {
        Form {
            Section(header: Text("TAG ID")) {
                Text(tagID)
                Button("In die Zwischenablage kopieren") {
                    UIPasteboard.general.string = tagID
                }
                Button("Teilen") {
                    let activityController = UIActivityViewController(activityItems: [tagID], applicationActivities: nil)
                    UIApplication.shared.windows.first?.rootViewController?.present(activityController, animated: true, completion: nil)
                }
            }
            Section {
                Button("Dublikat erstellen") {
                    NFCManager.shared.writeTag(with: tagID) { result in
                        // Handle result if needed
                    }
                }
                Button("Event auslösen") {
                    NFCManager.shared.triggerEvent(for: tagID)
                }
            }
        }
        .navigationTitle("Tag Details")
    }
}

struct TagDetailView_Previews: PreviewProvider {
    static var previews: some View {
        TagDetailView(tagID: "SampleTagID")
    }
}

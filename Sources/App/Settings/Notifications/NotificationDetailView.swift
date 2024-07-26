import SwiftUI
import WebKit
import AVKit

struct WebView: UIViewRepresentable {
    let htmlContent: String

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlContent, baseURL: nil)
    }
}

struct NotificationDetailView: View {
    var notification: NotificationModel

    var body: some View {
        VStack(alignment: .leading) {
            Text(notification.title)
                .font(.largeTitle)
            Text(notification.subtitle)
                .font(.title2)
                .foregroundColor(.gray)
            
            if let bodyHtml = notification.bodyHtml {
                WebView(htmlContent: bodyHtml)
            } else {
                WebView(htmlContent: notification.body)
            }
            
            if let imageUrl = notification.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    Color.gray
                }
                .frame(maxHeight: 300)
                .cornerRadius(10)
            }

            if let videoUrl = notification.videoUrl, let url = URL(string: videoUrl) {
                VideoPlayer(player: AVPlayer(url: url))
                    .frame(height: 300)
                    .cornerRadius(10)
                    .onAppear {
                        let player = AVPlayer(url: url)
                        player.play()
                    }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Notification Detail")
    }
}

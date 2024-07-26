import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        print("SceneDelegate: scene(_:willConnectTo:options:) called")
        
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        print("SceneDelegate: sceneDidDisconnect(_:)")
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        print("SceneDelegate: sceneDidBecomeActive(_:)")
    }

    func sceneWillResignActive(_ scene: UIScene) {
        print("SceneDelegate: sceneWillResignActive(_:)")
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        print("SceneDelegate: sceneWillEnterForeground(_:)")
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        print("SceneDelegate: sceneDidEnterBackground(_:)")
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        print("SceneDelegate: scene(_:openURLContexts:) called")
        
        guard let urlContext = URLContexts.first else { return }
        let url = urlContext.url
        print("SceneDelegate: Received URL: \(url)")

        if url.scheme == "iobrokerapp" {
            handleCustomURL(url)
        }
    }

    private func handleCustomURL(_ url: URL) {
        print("Handling URL: \(url)")
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
           let queryItems = components.queryItems {
            let tagId = queryItems.first(where: { $0.name == "tagId" })?.value
            let name = queryItems.first(where: { $0.name == "name" })?.value
            print("Tag ID: \(tagId ?? "Unknown"), Name: \(name ?? "Unknown")")
        }
    }
}

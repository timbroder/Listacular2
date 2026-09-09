import SwiftUI
@preconcurrency import SwiftyDropbox

@main
struct ListacularApp: App {
    @State private var store = DocumentStore()

    init() {
        DropboxClientsManager.setupWithAppKey("yz34wmzqt12u3ko")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .task {
                    await store.loadFromDisk()
                    _ = await NotificationService.requestPermission()
                }
                .onOpenURL { url in
                    if url.scheme == "listacular" {
                        store.handleURL(url)
                    } else {
                        DropboxSyncService.handleRedirectURL(url) { _ in }
                    }
                }
        }
    }
}

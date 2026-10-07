import SwiftUI

@main
struct AINoteTakerApp: App {
    @StateObject private var store = NoteStore()

    init() {
        NotificationManager.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}

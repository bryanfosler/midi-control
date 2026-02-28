import SwiftUI

@main
struct MIDIControlApp: App {
    @StateObject private var appViewModel = AppViewModel()

    init() {
        #if os(macOS)
        NSWindow.allowsAutomaticWindowTabbing = false
        #endif
    }

    var body: some Scene {
        #if os(macOS)
        WindowGroup {
            ContentView()
                .environmentObject(appViewModel)
                .frame(minWidth: 860, minHeight: 640)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1200, height: 820)
        #else
        WindowGroup {
            iOSContentView()
                .environmentObject(appViewModel)
        }
        #endif
    }
}

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
                .frame(minWidth: 1100, minHeight: 700)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1400, height: 850)
        #else
        WindowGroup {
            iOSContentView()
                .environmentObject(appViewModel)
        }
        #endif
    }
}

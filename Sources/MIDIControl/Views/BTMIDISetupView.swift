#if os(iOS)
import SwiftUI
import CoreAudioKit

/// Wraps CABTMIDICentralViewController to present Apple's built-in
/// Bluetooth MIDI device picker. Once a device is paired, CoreMIDI
/// sees it as a regular destination and MIDIManager.refreshDestinations()
/// picks it up automatically via the MIDIClientCreateWithBlock notification.
struct BTMIDISetupView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CABTMIDICentralViewController {
        CABTMIDICentralViewController()
    }

    func updateUIViewController(_ vc: CABTMIDICentralViewController, context: Context) {}
}
#endif

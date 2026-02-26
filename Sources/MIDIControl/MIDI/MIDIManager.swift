import Foundation
import CoreMIDI
import Combine

/// Wraps CoreMIDI to list output destinations and send CC/PC messages
class MIDIManager: ObservableObject {
    /// Available MIDI output destinations
    @Published var destinations: [MIDIDestination] = []
    /// Currently selected destination index (nil = none)
    @Published var selectedDestinationIndex: Int?
    /// Connection status description
    @Published var statusText: String = "No MIDI device selected"

    private var midiClient: MIDIClientRef = 0
    private var outputPort: MIDIPortRef = 0

    struct MIDIDestination: Identifiable, Equatable {
        let id: Int  // endpoint unique ID
        let endpoint: MIDIEndpointRef
        let name: String
    }

    init() {
        setupMIDI()
    }

    deinit {
        if outputPort != 0 {
            MIDIPortDispose(outputPort)
        }
        if midiClient != 0 {
            MIDIClientDispose(midiClient)
        }
    }

    // MARK: - Setup

    private func setupMIDI() {
        let clientName = "MIDIControl" as CFString

        // Create client with notification callback
        let status = MIDIClientCreateWithBlock(clientName, &midiClient) { [weak self] notification in
            let messageID = notification.pointee.messageID
            if messageID == .msgSetupChanged {
                DispatchQueue.main.async {
                    self?.refreshDestinations()
                }
            }
        }

        guard status == noErr else {
            statusText = "Failed to create MIDI client: \(status)"
            return
        }

        // Create output port
        let portName = "MIDIControl Output" as CFString
        let portStatus = MIDIOutputPortCreate(midiClient, portName, &outputPort)
        guard portStatus == noErr else {
            statusText = "Failed to create MIDI output port: \(portStatus)"
            return
        }

        refreshDestinations()
    }

    /// Refresh the list of available MIDI destinations
    func refreshDestinations() {
        var newDestinations: [MIDIDestination] = []
        let count = MIDIGetNumberOfDestinations()

        for i in 0..<count {
            let endpoint = MIDIGetDestination(i)
            let name = getDisplayName(for: endpoint)
            var uniqueID: MIDIUniqueID = 0
            MIDIObjectGetIntegerProperty(endpoint, kMIDIPropertyUniqueID, &uniqueID)
            newDestinations.append(MIDIDestination(
                id: Int(uniqueID),
                endpoint: endpoint,
                name: name
            ))
        }

        destinations = newDestinations

        // If selected destination disappeared, deselect
        if let idx = selectedDestinationIndex, idx >= destinations.count {
            selectedDestinationIndex = nil
            statusText = "MIDI device disconnected"
        }
    }

    /// Select a MIDI destination by index
    func selectDestination(at index: Int?) {
        selectedDestinationIndex = index
        if let index = index, index < destinations.count {
            statusText = "Connected: \(destinations[index].name)"
        } else {
            statusText = "No MIDI device selected"
        }
    }

    // MARK: - Send Messages

    /// Send a MIDI Control Change message
    /// - Parameters:
    ///   - channel: MIDI channel 1-16 (converted to 0-15 internally)
    ///   - cc: Controller number 0-127
    ///   - value: Controller value 0-127
    func sendCC(channel: Int, cc: Int, value: Int) {
        guard let endpoint = selectedEndpoint else { return }

        let statusByte = UInt8(0xB0 | ((channel - 1) & 0x0F))
        let ccByte = UInt8(cc & 0x7F)
        let valueByte = UInt8(value & 0x7F)

        sendBytes([statusByte, ccByte, valueByte], to: endpoint)
    }

    /// Send a MIDI Note On message
    func sendNoteOn(channel: Int, note: Int, velocity: Int) {
        guard let endpoint = selectedEndpoint else { return }
        let statusByte = UInt8(0x90 | ((channel - 1) & 0x0F))
        sendBytes([statusByte, UInt8(note & 0x7F), UInt8(velocity & 0x7F)], to: endpoint)
    }

    /// Send a MIDI Note Off message
    func sendNoteOff(channel: Int, note: Int) {
        guard let endpoint = selectedEndpoint else { return }
        let statusByte = UInt8(0x80 | ((channel - 1) & 0x0F))
        sendBytes([statusByte, UInt8(note & 0x7F), 0], to: endpoint)
    }

    /// Send a MIDI Program Change message
    /// - Parameters:
    ///   - channel: MIDI channel 1-16 (converted to 0-15 internally)
    ///   - program: Program number 0-127
    func sendPC(channel: Int, program: Int) {
        guard let endpoint = selectedEndpoint else { return }

        let statusByte = UInt8(0xC0 | ((channel - 1) & 0x0F))
        let programByte = UInt8(program & 0x7F)

        sendBytes([statusByte, programByte], to: endpoint)
    }

    // MARK: - Private Helpers

    private var selectedEndpoint: MIDIEndpointRef? {
        guard let index = selectedDestinationIndex, index < destinations.count else {
            return nil
        }
        return destinations[index].endpoint
    }

    private func sendBytes(_ bytes: [UInt8], to endpoint: MIDIEndpointRef) {
        var packetList = MIDIPacketList()
        var packet = MIDIPacketListInit(&packetList)
        packet = MIDIPacketListAdd(&packetList, MemoryLayout<MIDIPacketList>.size,
                                   packet, 0, bytes.count, bytes)

        let status = MIDISend(outputPort, endpoint, &packetList)
        if status != noErr {
            print("MIDI send error: \(status)")
        }
    }

    private func getDisplayName(for endpoint: MIDIEndpointRef) -> String {
        var name: Unmanaged<CFString>?
        let status = MIDIObjectGetStringProperty(endpoint, kMIDIPropertyDisplayName, &name)
        if status == noErr, let cfName = name {
            return cfName.takeRetainedValue() as String
        }
        return "Unknown Device"
    }
}

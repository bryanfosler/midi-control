import SwiftUI

/// Collapsible one-octave MIDI piano keyboard for MOOD MKii Synth Mode.
///
/// Mac keyboard layout (GarageBand style):
///   White keys  A S D F G H J  →  C D E F G A B
///   Black keys  W E   T Y U    →  C# D# / F# G# A#
///   Octave      Z = down  X = up
struct MiniKeyboardView: View {
    @ObservedObject var viewModel: PedalViewModel

    @State private var isExpanded: Bool = true
    @State private var octave: Int = 4
    @State private var activeNotes: Set<Int> = []
    @FocusState private var isFocused: Bool

    // MARK: - Key model

    private struct KeyInfo: Identifiable {
        let id: Int            // semitone offset from C (0–11)
        let isBlack: Bool
        let whiteIndex: Int    // white-key sequence index (0–6); black keys use left-neighbour index
        let keyChar: Character
        let label: String
    }

    private let keys: [KeyInfo] = [
        KeyInfo(id: 0,  isBlack: false, whiteIndex: 0, keyChar: "a", label: "C"),
        KeyInfo(id: 1,  isBlack: true,  whiteIndex: 0, keyChar: "w", label: "C#"),
        KeyInfo(id: 2,  isBlack: false, whiteIndex: 1, keyChar: "s", label: "D"),
        KeyInfo(id: 3,  isBlack: true,  whiteIndex: 1, keyChar: "e", label: "D#"),
        KeyInfo(id: 4,  isBlack: false, whiteIndex: 2, keyChar: "d", label: "E"),
        KeyInfo(id: 5,  isBlack: false, whiteIndex: 3, keyChar: "f", label: "F"),
        KeyInfo(id: 6,  isBlack: true,  whiteIndex: 3, keyChar: "t", label: "F#"),
        KeyInfo(id: 7,  isBlack: false, whiteIndex: 4, keyChar: "g", label: "G"),
        KeyInfo(id: 8,  isBlack: true,  whiteIndex: 4, keyChar: "y", label: "G#"),
        KeyInfo(id: 9,  isBlack: false, whiteIndex: 5, keyChar: "h", label: "A"),
        KeyInfo(id: 10, isBlack: true,  whiteIndex: 5, keyChar: "u", label: "A#"),
        KeyInfo(id: 11, isBlack: false, whiteIndex: 6, keyChar: "j", label: "B"),
    ]

    private var whiteKeys: [KeyInfo] { keys.filter { !$0.isBlack } }
    private var blackKeys: [KeyInfo] { keys.filter { $0.isBlack } }

    // MARK: - MIDI helpers

    private func midiNote(semitone: Int) -> Int { (octave + 1) * 12 + semitone }

    private func noteOn(semitone: Int) {
        let note = midiNote(semitone: semitone)
        guard !activeNotes.contains(note) else { return }
        activeNotes.insert(note)
        viewModel.sendNoteOn(note: note)
    }

    private func noteOff(semitone: Int) {
        let note = midiNote(semitone: semitone)
        activeNotes.remove(note)
        viewModel.sendNoteOff(note: note)
    }

    private func allNotesOff() {
        for note in activeNotes { viewModel.sendNoteOff(note: note) }
        activeNotes.removeAll()
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            headerBar

            if isExpanded {
                VStack(spacing: 8) {
                    pianoView
                    octaveBar
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 10)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(platformControlBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            isFocused
                                ? Color.accentColor.opacity(0.55)
                                : platformSeparatorColor,
                            lineWidth: isFocused ? 1.0 : 0.5
                        )
                )
        )
        .focusable()
        .focused($isFocused)
        .onKeyPress(phases: [.down, .up]) { handleKeyPress($0) }
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
    }

    // MARK: - Header bar

    private var headerBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "pianokeys")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Synth Keyboard")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            if !isFocused {
                Text("click to enable keys")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    isExpanded.toggle()
                    if !isExpanded { allNotesOff() }
                }
            } label: {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Piano keys

    private var pianoView: some View {
        GeometryReader { geo in
            let wkw = geo.size.width / CGFloat(whiteKeys.count)  // white key width
            let wkh: CGFloat = 78
            let bkw = wkw * 0.60                                  // black key width
            let bkh: CGFloat = 48

            ZStack(alignment: .topLeading) {
                // White keys
                HStack(spacing: 0) {
                    ForEach(whiteKeys) { key in
                        whiteKeyView(key, width: wkw, height: wkh)
                    }
                }
                // Black keys — centered at the boundary between adjacent white keys
                ForEach(blackKeys) { key in
                    blackKeyView(key, width: bkw, height: bkh)
                        .offset(x: CGFloat(key.whiteIndex + 1) * wkw - bkw / 2)
                }
            }
        }
        .frame(height: 80)
    }

    @ViewBuilder
    private func whiteKeyView(_ key: KeyInfo, width: CGFloat, height: CGFloat) -> some View {
        let note = midiNote(semitone: key.id)
        let pressed = activeNotes.contains(note)

        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 3)
                .fill(pressed ? Color(red: 0.78, green: 0.88, blue: 1.0) : Color.white)
            RoundedRectangle(cornerRadius: 3)
                .strokeBorder(Color(white: 0.62), lineWidth: 0.5)
            VStack(spacing: 1) {
                Text(String(key.keyChar).uppercased())
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(Color(white: 0.45))
                Text(key.label)
                    .font(.system(size: 7))
                    .foregroundStyle(Color(white: 0.62))
            }
            .padding(.bottom, 5)
        }
        .frame(width: width, height: height)
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { _ in noteOn(semitone: key.id) }
                .onEnded   { _ in noteOff(semitone: key.id) }
        )
    }

    @ViewBuilder
    private func blackKeyView(_ key: KeyInfo, width: CGFloat, height: CGFloat) -> some View {
        let note = midiNote(semitone: key.id)
        let pressed = activeNotes.contains(note)

        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 2)
                .fill(pressed ? Color(white: 0.32) : Color(white: 0.10))
            RoundedRectangle(cornerRadius: 2)
                .strokeBorder(Color(white: 0.06), lineWidth: 0.5)
            Text(String(key.keyChar).uppercased())
                .font(.system(size: 7, weight: .medium))
                .foregroundStyle(Color(white: 0.55))
                .padding(.bottom, 4)
        }
        .frame(width: width, height: height)
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { _ in noteOn(semitone: key.id) }
                .onEnded   { _ in noteOff(semitone: key.id) }
        )
    }

    // MARK: - Octave bar

    private var octaveBar: some View {
        HStack(spacing: 10) {
            Button { allNotesOff(); octave = max(0, octave - 1) } label: {
                Image(systemName: "minus.circle")
                    .foregroundStyle(octave <= 0 ? Color.secondary.opacity(0.4) : Color.secondary)
            }
            .buttonStyle(.plain)
            .disabled(octave <= 0)
            .help("Octave down  (Z)")

            Text("Octave \(octave)")
                .font(.system(size: 11, weight: .medium).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 66)

            Button { allNotesOff(); octave = min(8, octave + 1) } label: {
                Image(systemName: "plus.circle")
                    .foregroundStyle(octave >= 8 ? Color.secondary.opacity(0.4) : Color.secondary)
            }
            .buttonStyle(.plain)
            .disabled(octave >= 8)
            .help("Octave up  (X)")

            Spacer()

            Text("A–J · W/E/T/Y/U · Z/X oct")
                .font(.system(size: 9))
                .foregroundStyle(.quaternary)
        }
    }

    // MARK: - Platform colors

    private var platformControlBackground: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(.secondarySystemBackground)
        #endif
    }

    private var platformSeparatorColor: Color {
        #if os(macOS)
        Color(nsColor: .separatorColor)
        #else
        Color(.separator)
        #endif
    }

    // MARK: - Keyboard input

    private func handleKeyPress(_ press: KeyPress) -> KeyPress.Result {
        if press.key == KeyEquivalent("z") {
            if press.phase == .down { allNotesOff(); octave = max(0, octave - 1) }
            return .handled
        }
        if press.key == KeyEquivalent("x") {
            if press.phase == .down { allNotesOff(); octave = min(8, octave + 1) }
            return .handled
        }
        if let key = keys.first(where: { KeyEquivalent($0.keyChar) == press.key }) {
            if press.phase == .down { noteOn(semitone: key.id) }
            else if press.phase == .up { noteOff(semitone: key.id) }
            return .handled
        }
        return .ignored
    }
}

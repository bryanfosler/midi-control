# MIDIControl - Chase Bliss MIDI Controller

## Project Overview
A native macOS SwiftUI app for controlling Chase Bliss guitar pedals via MIDI.

## Hardware
- **Chase Bliss Brothers AM** — dual analog gain stage (boost/drive/fuzz)
- **Chase Bliss MOOD MKII** — micro-looper + wet effects (delay/reverb/slip)
- Both pedals are **receive-only** (no MIDI out) — app must track all state internally
- Connected via USB MIDI interface (e.g., CME C2MIDI Pro)

## Architecture
- **MVVM** with SwiftUI + CoreMIDI
- `PedalDefinition` — static CC tables hardcoded in Swift (type-safe)
- `PedalState` — live runtime values per pedal instance
- `PedalViewModel` — bridges state to UI, sends MIDI on value change
- `MIDIManager` — CoreMIDI wrapper (list devices, send CC/PC)
- `PresetStorage` — JSON files in `~/Library/Application Support/MIDIControl/presets/`

## MIDI Details
- MIDI channels are 1-16 in UI, 0-15 in wire protocol
- CC values are always 0-127
- **Brothers AM = ch 2, MOOD MKII = ch 3** (28 CC numbers overlap — different channels required)
- CC 104, value = (targetChannel − 1) = Chase Bliss channel-change command (send on CURRENT channel)
- Sliders send CC on every value change (real-time, not on-release)
- Footswitch params send CC value 127 as a momentary trigger

## Build & Run
```bash
swift build        # compile
swift run          # run (GUI requires Xcode for full SwiftUI support)
open Package.swift # open in Xcode for GUI development
```

## Shared Utilities
ProgressTracker is linked as a local SPM dependency from `~/utils/swift/`.
- SPM identifies local packages by **folder name**, not `Package.swift` name
- Reference: `.product(name: "ProgressTracker", package: "swift")`
- Use for terminal/CLI progress output; in-app progress uses SwiftUI `ProgressView`

## SwiftUI / macOS Patterns (hard-won)
- **`PedalState` is a CLASS** — mutations to `state.values` fire `state.objectWillChange` but NOT `viewModel.objectWillChange`. Fix: Combine forwarding in PedalViewModel init: `state.objectWillChange.sink { self?.objectWillChange.send() }`
- **Interactive controls** use `@State var liveValue/liveIndex` for instant visual feedback; synced back from binding via `onAppear` + `onChange(of:)`
- **Gesture coordinate space**: always use `coordinateSpace: .local` so `startLocation.x/y` is relative to the view (0…width), not screen-absolute
- **Tooltips**: `.help()` must be on the **innermost interactive view** (same layer as gesture), not a parent container
- **`Color.clear` doesn't hit-test on macOS** — use `Color.white.opacity(0.001)` for invisible tap targets
- **`DragGesture(minimumDistance: 0, coordinateSpace: .local)`** is the reliable tap+drag pattern on macOS; more dependable than `onTapGesture` with location
- **`.help()` placement**: put on the view with the gesture, not a parent wrapper

## Key Files
- `Models/Pedals/BrothersAMDefinition.swift` — Brothers AM CC table
- `Models/Pedals/MoodMKIIDefinition.swift` — MOOD MKII CC table
- `MIDI/MIDIManager.swift` — CoreMIDI integration
- `ViewModels/PedalViewModel.swift` — per-pedal logic
- `Storage/PresetStorage.swift` — preset persistence

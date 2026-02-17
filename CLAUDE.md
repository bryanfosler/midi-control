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
- Both pedals default to channel 2
- Sliders send CC on every value change (real-time, not on-release)
- Footswitch params send CC value 127 as a momentary trigger

## Build & Run
```bash
swift build        # compile
swift run          # run (GUI requires Xcode for full SwiftUI support)
open Package.swift # open in Xcode for GUI development
```

## Key Files
- `Models/Pedals/BrothersAMDefinition.swift` — Brothers AM CC table
- `Models/Pedals/MoodMKIIDefinition.swift` — MOOD MKII CC table
- `MIDI/MIDIManager.swift` — CoreMIDI integration
- `ViewModels/PedalViewModel.swift` — per-pedal logic
- `Storage/PresetStorage.swift` — preset persistence

# Bryan Learns: MIDIControl Architecture

## How the App Works (Big Picture)

The app is a **MIDI controller** — it sends MIDI messages to your Chase Bliss pedals so you can tweak knobs, flip toggles, and save/load presets from your Mac instead of bending down to the pedalboard.

### The Flow
```
You move a slider in the app
  → PedalViewModel updates the PedalState
  → PedalViewModel tells MIDIManager to send a CC message
  → MIDIManager sends bytes over CoreMIDI
  → Your USB MIDI interface delivers it to the pedal
  → The pedal changes its parameter
```

## Key Concepts

### MIDI Control Change (CC)
MIDI CC messages are 3 bytes:
1. **Status byte**: `0xB0` + channel (0-15) — "this is a CC message on channel N"
2. **CC number**: 0-127 — which parameter to change (e.g., CC14 = Gain on Brothers)
3. **Value**: 0-127 — the new value

So `[0xB1, 14, 100]` means "on channel 2, set CC14 (Gain) to 100."

### Why MVVM?
- **Model** (`PedalDefinition`, `PedalState`, `Preset`): Pure data — what a pedal *is* and what its current values *are*
- **ViewModel** (`PedalViewModel`, `AppViewModel`): Logic — when you move a slider, it updates the model AND sends MIDI
- **View** (`PedalView`, `KnobSlider`, etc.): Pure UI — renders the current state, calls ViewModel methods on interaction

This separation means the MIDI logic doesn't live in the views, making it testable and portable to iOS later.

### PedalDefinition System
Each pedal is defined as a list of `ParameterDefinition`s. Each parameter knows:
- Its **CC number** (what MIDI message to send)
- Its **type** (knob = continuous slider, toggle = discrete options, dipSwitch = on/off, footswitch = momentary)
- Its **section** (for grouping in the UI)

The pedal definitions are static data — they describe the pedal's capabilities but don't hold runtime state.

### Why CoreMIDI (not a library)?
CoreMIDI is Apple's native MIDI framework. It's low-level but:
- Zero dependencies
- Works on macOS and iOS
- Full control over timing and message format
- The API surface we need is tiny (create client, create output port, send bytes)

### Preset Storage
Presets are saved as individual JSON files in `~/Library/Application Support/MIDIControl/presets/{pedal-id}/`. This is:
- Simple (no database)
- Easy to backup (just copy the folder)
- Easy to share (send someone a .json file)
- Standard macOS practice for app data

## SwiftUI Patterns Used

### @ObservableObject + @Published
ViewModels are `ObservableObject` classes. Properties marked `@Published` automatically trigger view updates when they change. This is how moving a slider instantly updates the value display.

### @EnvironmentObject
The `AppViewModel` is injected at the top of the view hierarchy and available to all child views via `@EnvironmentObject`. This avoids passing it through every view's init.

### Binding
`Binding<Int>` is a two-way connection between a view and its data source. When a slider moves, it writes through the binding; when the ViewModel changes the value, the slider updates.

## What's Next (Future Phases)
- iOS companion app (the architecture is already portable)
- User-defined pedal definitions (JSON import)
- MIDI learn mode
- Sequence/automation recording

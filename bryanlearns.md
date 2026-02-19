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

---

## Session 3 Lessons: Xcode, SwiftUI Layout, and AppKit Interop

### Swift Package ≠ macOS App — A Subtle Trap

When you build with `swift run`, Swift Package Manager runs your executable directly. That's great for CLI tools, but macOS apps need a proper **app bundle** — a folder structure ending in `.app` that contains your binary, an `Info.plist`, icons, and more. Without that bundle:

- There's no `CFBundleIdentifier`, so macOS can't index the window
- The app window sometimes never appears
- You get cryptic errors like "Cannot index window tabs due to missing main bundle identifier"

The fix: generate a real `MIDIControl.xcodeproj` using **xcodegen**, a tool that reads a `project.yml` file and outputs a valid Xcode project. You just install it once with Homebrew (`brew install xcodegen`) and run `xcodegen generate` any time you add new files.

**The takeaway:** For any real macOS app, you want an `.xcodeproj`, not just a `Package.swift`. xcodegen lets you describe your project in simple YAML and regenerate the `.xcodeproj` automatically — no more hand-editing that terrifying `project.pbxproj` file.

### SwiftUI Layout: ZStack + VStack for Realistic Controls

The pedal enclosure is a `ZStack` — the background shell rendered first, then the content `VStack` drawn on top. That's the same pattern used everywhere in SwiftUI when you want a shaped background with content inside it.

Inside the `VStack`, content is ordered top-to-bottom to match the physical pedal:
```
Knob rows → Toggle row → Brand section → Footswitches
```

A key trick for evenly distributing 3 knobs across a fixed width is wrapping them in `HStack` with `Spacer(minLength: 0)` between and around them. SwiftUI's `Spacer` is greedy — it expands to fill available space — so alternating knobs and spacers creates equal gaps automatically.

### NSViewRepresentable: Reaching Into AppKit When SwiftUI Falls Short

SwiftUI doesn't support scroll wheel events natively on macOS (as of early 2026). But `NSView` — the older AppKit view class — does. `NSViewRepresentable` is SwiftUI's bridge to AppKit: you wrap an `NSView` subclass so SwiftUI can use it like any other view.

For the scroll wheel:
1. Subclass `NSView`, override `scrollWheel(with:)` — this is called automatically whenever the mouse wheel or trackpad scrolls over the view
2. Wrap it in a `NSViewRepresentable` struct
3. Place it as the bottom layer of the knob's `ZStack` — it catches events even though you can't see it

```
ZStack {
    ScrollWheelHandler { delta in ... }  ← invisible, catches scroll
    [visual layers on top]
}
```

**The aha moment:** AppKit has decades of mature event handling that SwiftUI hasn't fully caught up to yet. Knowing how to drop down to `NSView` when needed is a critical macOS skill — it's not a hack, it's the intended architecture.

### ForEach Needs Truly Unique IDs

SwiftUI's `ForEach` requires a unique identifier for each item so it can track which views to update when data changes. When we used `\.x` (the x coordinate) as the ID for corner screw positions, two corners shared the same x value (the left side inset), causing a warning.

The fix is simple: use `array.indices` (the position numbers 0, 1, 2, 3) as IDs when the data items aren't naturally unique. Index positions are always unique within an array.

---

## Swift Package Manager's Secret Identity Crisis

Here's a quirk that bit us: when you add a local Swift package as a dependency, SPM identifies it by its **folder name**, not the `name` field inside `Package.swift`.

So if your package lives at `~/utils/swift/` and inside `Package.swift` you wrote `name: "ProgressTracker"`, you'd think the package is called "ProgressTracker". Nope — SPM calls it "swift" (the folder).

When you try to reference the product in your app's target dependencies:
```swift
// This fails — SPM doesn't know "ProgressTracker" as a package name
dependencies: ["ProgressTracker"]

// This also fails
dependencies: [.product(name: "ProgressTracker", package: "ProgressTracker")]

// This works — "swift" is the folder name, "ProgressTracker" is the product
dependencies: [.product(name: "ProgressTracker", package: "swift")]
```

The mental model: the `name` in `Package.swift` is what shows up in Xcode's UI and in published packages on package registries. But for local path-based packages, SPM uses the directory name as its internal handle. It's like naming your dog "Sir Fluffington" on his vet registration but calling him "Buddy" at home — SPM only knows the home name.

**Takeaway:** When naming your local utility folders, pick something unambiguous. Naming a Swift package folder "swift" is technically fine but confusing — something like "ProgressTracker" or "swift-utils" would have made the `package:` reference more intuitive.

---

## What's Next (Future Phases)
- Visual polish and hardware testing
- iOS companion app (the architecture is already portable)
- User-defined pedal definitions (JSON import)
- MIDI learn mode
- Sequence/automation recording

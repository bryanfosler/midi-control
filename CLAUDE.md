# MIDIControl - Chase Bliss MIDI Controller

## Project Overview
A native macOS SwiftUI app for controlling Chase Bliss guitar pedals via MIDI.

## Hardware
- **Chase Bliss Brothers AM** — dual analog gain stage (boost/drive/fuzz)
- **Chase Bliss MOOD MKII** — micro-looper + wet effects (delay/reverb/slip)
- Both pedals are **receive-only** (no MIDI out) — app must track all state internally
- Connected via USB MIDI interface (e.g., CME C2MIDI Pro)

## Reference Manuals (local)
All manuals are in `~/Documents/Claude/Midi Control/` — **check here before searching the web:**
- `Brothers+AM_Manual_Pedal_Chase+Bliss.pdf` — full field guide (knob layout, presets, dips, presence)
- `Brothers-AM_MIDI-Manual_Pedal_Chase-Bliss.pdf` — MIDI CC reference
- `MOOD+MKII_Manual_Pedal_Chase+Bliss.pdf` — full MOOD MKII guide
- `MOOD+MKII_MIDI+Manual_Pedal_Chase+Bliss.pdf` — MOOD MKII MIDI CC reference
- `Dip+Switches+101_Chase+Bliss.pdf` — dip switch behavior guide

## DIY MIDI-to-TRS Converter Box (1590B)
- **Enclosure**: Hammond 1590B — 112mm × 60mm × 31mm exterior
- **Layout (Option B)**: TRS jacks on long side, DIN IN + DIN THRU on Short Side A, SPDT switches on top face, Short Side B blank
- **Hole sizes**: DIN = 5/8" (16mm), TRS = 3/8" (9.5mm), switch slots = 3mm × 8mm
- **TRS jack positions (long side)**: 16mm, 38mm, 60mm, 82mm from left, centered vertically at 15mm
- **DIN positions (short side A)**: 18mm and 42mm from left, centered vertically at 15mm
- **Switch positions (top face)**: 16mm, 38mm, 60mm, 82mm from left, centered at 30mm
- **MIDI Thru**: passive (no power needed) — pins 5 and 2 of DIN THRU wired directly to DIN IN
- **No power supply** — fully passive design; 18 wires total

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
- **midiChannel persistence** — saved to `UserDefaults` keyed `pedal_<definition.id>_midiChannel`; loaded in `PedalViewModel.init()` with fallback to `definition.defaultChannel`
- **Both pedals MUST be on different channels** — CC tables overlap; same channel = phantom state changes (knob on one pedal triggers footswitch on other)
- **Factory presets are data, not code** — `FactoryPresets.swift` structs seed JSON on first launch. A wrong value (e.g., `midiChannel: 2` instead of `3`) gets saved to disk and persists across updates. Fixing the source alone isn't enough — also bump the seed version key AND add a migration for already-saved presets. Pattern: `seedIfNeeded` runs a one-time migration (gated by its own UserDefaults key) before the guard that skips re-seeding.
- **`PedalState.loadValues` must be a full reset** — resets all params to defaults first, then overlays preset values. Additive-only approach lets CC values from previous presets bleed through for CCs not in the new preset.

## Community Preset Import (CB Presets App)

- Script: `import_cb_presets.py` at repo root — run with `python3 import_cb_presets.py`
- Source: Chase Bliss Presets iOS app backup (`ChaseBlissPresets.json` exported from app → Files)
- Filters to `brothersAM` (17 total, 4 skipped for factory name overlap → 13 imported) + `moodMKII` (31 imported)
- All imported presets tagged `"cb-presets"` — batch-remove before App Store submission
- **Physical → CC mapping (Brothers AM):** top row L→R = Gain 2 (CC14), Vol 2 (CC15), Gain 1 (CC16); bottom row = Tone 2 (CC17), Vol 1 (CC18), Tone 1 (CC19); toggles L/M/R = CC21/22/23 (values 0/2/3); presence hidden opts: bottomLeft→CC27, bottomRight→CC29
- **Physical → CC mapping (MOOD MKII):** top row = Time (CC14), Mix (CC15), Length (CC16); bottom row = ModifyWet (CC17), Clock (CC18), ModifyLoop (CC19); toggles L/M/R = CC21/22/23 (values 0/2/127); ramp→CC20; hidden knobs topL→CC24 … bottomR→CC29; hidden toggles L/M→CC31/32, Buffer Length→CC33 (left=0, right=127)
- Dip switches (both pedals): row1 dips 1–8 → CC 61–68; row2 dips 1–8 → CC 71–78; true→127, false→0

## Build & Run
```bash
swift build        # compile (verifies correctness from terminal)
xcodegen generate  # MUST run after any Swift file add/remove — regenerates .xcodeproj
open MIDIControl.xcodeproj  # correct way to open for GUI development
```
- **NEVER open `Package.swift`** to run the app — it builds a CLI target, not the GUI app
- **`MIDIControl.xcodeproj` is gitignored** (generated by xcodegen from `project.yml`)
- After adding/removing any `.swift` file, run `xcodegen generate` or Xcode will give "Cannot find X in scope"
- **Two targets:** `MIDIControl` (macOS 14+) and `MIDIControliOS` (iOS 17+) — same `Sources/MIDIControl/` folder
- **iOS plist keys** go in `project.yml` under `info.properties` — never hand-edit `Info_iOS.plist`, xcodegen regenerates it
- **Platform conditionals:** `#if os(macOS)` / `#if os(iOS)` used throughout; AppKit types must be guarded

## iOS Launch Screen
- **`UILaunchScreen: {}`** must be in `project.yml` `info.properties` — without it iOS letterboxes the app with black bars at top/bottom on modern iPhones (the OS assumes an older, smaller-screen app)
- Empty dict `{}` is sufficient — no custom branding needed, just the key's presence
- After adding this, **delete and reinstall** the app on device to clear the cached letterbox behavior

## iOS Device Testing (free personal team)
- **After each `xcodegen generate`**: must re-select Personal Team in Xcode → MIDIControliOS target → Signing & Capabilities (the xcodeproj is gitignored so the team selection doesn't persist)
- **Developer Mode**: required on iOS device — Settings → Privacy & Security → Developer Mode → ON → restart (one-time per device)
- **First launch trust**: Settings → General → VPN & Device Management → Apple ID → Trust (one-time per cert)
- **7-day expiry**: provisioning profile expires after 7 days; fix by hitting Play in Xcode again — app data survives, just the authorization resets
- **No App Store needed** for personal use — sideload via Xcode is fully functional

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
- **`.background` vs ZStack for decorative layers** — `.background` is layout-invisible (won't shift surrounding views); ZStack sizes to its largest child. Use `.background` for glows, shadows, halos
- **Timer during mouse-hold** — add to `RunLoop.main` with mode `.common` (`RunLoop.main.add(timer, forMode: .common)`); tracking mode blocks `.default` timers
- **Keyboard piano input** — `@FocusState` + `.focusable()` + `.onKeyPress(phases: [.down, .up])` on macOS 14+; handle both phases in one modifier
- **iPad orientation detection** — size classes are `.regular` in BOTH portrait and landscape on iPad; use `GeometryReader { geo in geo.size.width > geo.size.height }` to detect landscape
- **iPhone landscape** — `verticalSizeClass == .compact` correctly identifies iPhone landscape (iPad stays `.regular`)
- **Responsive enclosure scaling** — `scaleEffect(s)` + double `.frame` trick: first frame at natural size, scaleEffect shrinks rendering, second frame tells layout the scaled size
- **`.principal` toolbar placement** — puts any view in the nav bar center (replaces title); use for pedal picker to save ~48pt vs a separate picker row
- **iOS deployment target: 17.0** — required for `.onKeyPress(phases:)`; `MiniKeyboardView` uses `#if os(macOS)` color helpers for cross-platform colors
- **`.contentShape(Rectangle())` for full-width button tap area** — with `.buttonStyle(.plain)`, hit testing is delegated to the label's rendered content; `Spacer()` is transparent so gaps are dead zones. Fix: put `.contentShape(Rectangle())` on the `HStack` **inside** the label, not on the outer `Button`. Putting it on the Button does nothing.
- **iOS Simulator type-checker timeout** — complex inline expressions (ternary + string interpolation + arithmetic) in a single view body can time out on x86_64 simulator builds even when macOS (arm64) compiles fine. Fix: extract to computed properties outside `body`.

## Key Files
- `Models/Pedals/BrothersAMDefinition.swift` — Brothers AM CC table
- `Models/Pedals/MoodMKIIDefinition.swift` — MOOD MKII CC table
- `MIDI/MIDIManager.swift` — CoreMIDI integration
- `ViewModels/PedalViewModel.swift` — per-pedal logic
- `Storage/PresetStorage.swift` — preset persistence

## Visual Design Reference (hard-won)

### Toggle bat switches
- Physical CB toggle switches: bat pivots from CENTER of housing
- Correct top-down rendering: portrait oval (tall + narrow) that SHIFTS HORIZONTALLY
- DO NOT use `rotationEffect` on the bat — it looks wrong. Use xShift + no rotation.
- Left = oval shifts left, Center = circle, Right = oval shifts right
- ovalW ≈ 0.58× batDiameter, ovalH ≈ 1.55× batDiameter when tilted

### Knob visual layers (top to bottom in ZStack)
1. Arc track (static 270° guide)
2. Active arc glow (wider blurred layer) + crisp arc on top
3. Drop shadow
4. Outer grip ring (machined aluminum gradient)
5. KnurlingRing (Canvas ±45° crosshatch, lineOpacity≈0.40, lineWidth≈0.65)
6. Inner dome rim (strokeBorder)
7. Dome body (RadialGradient)
8. Machined lathe rings (Canvas concentric circles, clipped to dome)
9. Specular highlights
10. Recessed indicator groove (rotates with value)

### Chase Bliss logos
- CB logo between footswitches: thin ring + "CB" text, NOT any SF Symbol person/figure
- AM badge (Brothers): 12-spike star OUTLINE (stroke, not fill) + filled gold circle center + "AM" text
- MOOD brand: large bold italic "MOOD" with sunset gradient, "MKii" bottom-right corner

## App Icon

`Views/AppIconView.swift` — pure SwiftUI Canvas drawing of the 1024×1024 app icon.
Design: dark maroon pedal enclosure + 1/4" TS cables plugged into both sides + central amber-arc knob.

**To export the PNG for the asset catalog:**
1. Open `AppIconView.swift` in Xcode
2. Open the Preview canvas (Option+Cmd+Return or the Canvas button)
3. Select the `"1024×1024 full"` preview
4. Right-click the preview → "Save Image…" (or use the share icon)
5. Save as `AppIcon-1024.png`
6. Move it to: `Sources/MIDIControl/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`
7. Run `xcodegen generate` (asset catalog is already wired; ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon)

**Asset catalog location:** `Sources/MIDIControl/Assets.xcassets/AppIcon.appiconset/`
**project.yml setting:** `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` (iOS target only)

## V2 Image-Based UI (tabled — assets ready)
Generated PNG assets are in `~/Documents/Claude/Midi Control/Pedal UI Images/`:
- `Brothers AM Base enclosure.png`, `MoodMK2 base enclosure.png` — full pedal photos (NOT usable as interactive backgrounds; controls baked in + front-facing angle)
- `left bat switch.png`, `center bat switch.png`, `right bat switch.png` — 3-state image swap for toggles
- `Plum knob pink indicator.png`, `Plum knob white indicator.png`, `Plum knob yellow indicator.png` — indicator at 12 o'clock; rotate whole image for knob turn

**Recommended approach (Option A):** Image knobs + bat switch images, drawn enclosure stays. Work on branch `v2-image-based`.
Visual mock at `~/Documents/Claude/Midi Control/v2-image-mock.html`.

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

## The "Ghost State" Problem — Why Your UI Lies to You

This session had one recurring villain: **a class pretending to be a value type**.

`PedalState` is a Swift **class** (`class PedalState: ObservableObject`). When you change a knob, the app calls `state.values[cc] = newValue`. This mutation fires `state.objectWillChange` — which tells SwiftUI "hey, re-render anything subscribed to *state*."

But the UI subscribes to `viewModel`, not `state` directly. The `PedalViewModel` has `@Published var state: PedalState`. SwiftUI only watches for changes to the *reference* — i.e., "did `state` get replaced with a new PedalState object?" When you mutate `state.values`, the reference doesn't change. So `viewModel.objectWillChange` never fires. And all the views watching `viewModel`? They just... don't update.

This is the "ghost state" problem — the data changed, but the UI didn't notice.

### We hit this bug in three different places:

**1. Knob visuals during drag** — You'd drag a knob and nothing moved until you released. The fix: `@State var liveValue` inside RotaryKnob. `@State` is local to the view and always triggers an immediate re-render, bypassing the whole ViewModel observation chain entirely.

**2. Bat switch not animating on click** — Same thing. `@State var liveIndex` inside ToggleSwitch3Way gave the bat immediate visual feedback.

**3. DipSwitchPanel stale after preset load** — When you loaded a preset, the dip switches didn't update. The fix this time: add a **Combine pipeline** in PedalViewModel that forwards `state.objectWillChange` to `viewModel.objectWillChange`:

```swift
stateCancellable = state.objectWillChange
    .sink { [weak self] _ in self?.objectWillChange.send() }
```

Now every mutation to `state.values` (preset loads, resets) propagates correctly to all observing views.

**The lesson:** If a SwiftUI `@ObservableObject` contains a *class* property (not a struct), mutations to that inner class's properties are invisible to observers of the outer object. You either fix it at the source (forwarding) or at the view level (local `@State`). Both are valid — use forwarding for panels that need to reflect external changes, use `@State` for interactive controls that need to be instantaneous.

---

## SwiftUI Gesture Hit-Testing on macOS — A Minefield

Building the bat switch and knob interactions taught us that **SwiftUI's gesture system on macOS has several gotchas that don't exist on iOS**.

### Gotcha 1: `Color.clear` doesn't receive taps on macOS

If you put a `Button` with a `Color.clear` background, the button won't respond to clicks on macOS. The workaround: `Color.white.opacity(0.001)` — technically visible but imperceptibly so, and it hits.

### Gotcha 2: Overlay buttons get clipped to the parent frame

If you put 32pt-tall buttons as an `.overlay()` on an 18pt ZStack, the buttons physically exist outside the 18pt frame but **SwiftUI's hit-testing only covers the layout frame**. The overflow area is invisible to the gesture system. This wasted several attempts trying to get bat switch clicks to work.

The fix: use `.onTapGesture { location in }` or `DragGesture(minimumDistance:0)` on the **parent** container with `.contentShape(Rectangle())`, so the entire parent area (including label rows above and name below) is one unified hit target.

### Gotcha 3: `.global` vs `.local` coordinate space

`DragGesture(coordinateSpace: .global)` gives you the cursor position in screen coordinates — `startLocation.x` could be 800, 1200, whatever. When we checked `startLocation.x > 29` to determine "did the user click the right half of the 58pt knob?", it was almost always true. The fix: `.local` gives you coordinates relative to the view itself (0–58), so `> 29` actually means "right half."

### Gotcha 4: Tooltips only work on the view that receives mouse events

`.help("some tooltip")` registers a `toolTip` on the underlying AppKit NSView. macOS shows it when the cursor rests over that NSView. But if a *child* view has a gesture recognizer consuming mouse events, the *parent* view's tooltip never fires — macOS can't tell the cursor is hovering over the parent because the child is in the way. Move `.help()` to the **innermost interactive view**, not a parent container.

---

## MIDI Channels — Why Your Pedals Are Talking Over Each Other

Two pedals. Both on channel 2. You move a knob in the Brothers AM column. Both pedals receive the message. Chaos.

Brothers AM and MOOD MKII share **28 overlapping CC numbers** — including all the main knobs (CC 14–19) and all dip switches (CC 61–68, 71–78). They just happen to use the same CC numbers for different things. There's no conflict in the physical pedals themselves — they'd never be on the same channel in real life.

The solution is setting each pedal to a **different MIDI channel** on the hardware. Chase Bliss does this via **CC 104** — the "change my channel" command. The value is `targetChannel - 1` (so channel 3 = value 2). Crucially, it must be sent on the pedal's *current* channel — you can't send on the new channel to change to it, because the pedal isn't listening there yet.

We built this into the app: the "Set Channel" button sends CC 104 on the current channel, then updates the app to match. One click, no manual hardware button-pressing.

---

## What's Next (Future Phases)
- Visual polish and hardware testing
- iOS companion app (the architecture is already portable)
- User-defined pedal definitions (JSON import)
- MIDI learn mode
- Sequence/automation recording

---

## Session 11: The Bat Switch Saga — Animations, Shapes, and the Xcode File Mystery

### The Problem with "Just Rotate It"

When you look at a real Chase Bliss pedal, the toggle switches have these metal bat levers that tilt left or right. Sounds simple to replicate, right? Just draw an oval and rotate it. Except — past-Bryan already tried that, and it looked wrong. The reason is subtle but important: **rotation and foreshortening are different things**.

When a physical bat tilts left, what you see from directly above is:
- The dome getting narrower (less circular, more oval)
- The oval *shifting sideways*, not rotating

So the first implementation used a "top-down physics" approach — a portrait oval that shifts horizontally. Correct physics, but it doesn't *read* as a pivot. Users couldn't tell it was hinged at a point.

### Two Design Options, One Key Insight

We designed two alternatives:

**Option B — Stem + Dome**: A thin chrome stem extends from the hex nut (pivot point) upward, with a small oval "dome cap" at the tip. Two separate pieces. This makes the pivot relationship *visible* — you can see where it hinges.

**Option A — Rotating Paddle**: One unified tapered paddle shape (like a little tennis racket or guitar pick) that rotates as one piece around its base. This is how the physical switch actually works — one rigid lever pivoting on a fixed point.

Bryan picked Option A. Why? Because it reads as a single physical object with weight and mass. Option B looked more like a diagram.

### How You Animate a Custom Shape

Here's the interesting engineering part. In SwiftUI, you can't animate what's *drawn inside* a Canvas — the canvas just redraws from scratch and there's no frame-by-frame interpolation of the drawing.

The solution: create a custom `Shape` that conforms to the `Animatable` protocol. When you mark a property as `animatableData`, SwiftUI will interpolate it between the old and new value every frame during an animation — automatically calling `path(in:)` with intermediate values.

```swift
struct RotatingPaddle: Shape {
    var angle: Double
    
    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        // Build the paddle pointing straight up, then rotate it
        // using CGAffineTransform around the pivot point
        let t = CGAffineTransform(translationX: -cx, y: -cy)
            .concatenating(CGAffineTransform(rotationAngle: CGFloat(angle * .pi / 180)))
            .concatenating(CGAffineTransform(translationX: cx, y: cy))
        return paddlePath.applying(t)
    }
}
```

The key: **all the rotation math is inside the path**, not in a SwiftUI modifier. No `rotationEffect` needed, which was previously found to look wrong on the oval bat.

### The Xcode "Cannot Find X in Scope" Mystery

We hit this multiple times and it was frustrating. Here's exactly what causes it:

**The `MIDIControl.xcodeproj` file is in `.gitignore`**. This means it's generated by a tool called `xcodegen` from a `project.yml` config file. `xcodegen` scans the `Sources/` folder and automatically includes all `.swift` files it finds.

When you create a new Swift file *outside of Xcode* (e.g., Claude writing it via terminal), `xcodegen` hasn't run yet, so the `.xcodeproj` doesn't know the file exists. Xcode can't compile what it doesn't know about.

**The fix**: After any file add or remove, run:
```bash
cd ~/Documents/Claude/Midi\ Control/MIDIControl
xcodegen generate
```

Then reopen `MIDIControl.xcodeproj` in Xcode.

**Also important**: Always open `MIDIControl.xcodeproj` to run the app — NOT `Package.swift`. Opening `Package.swift` launches it as a Swift Package Manager project, which builds a command-line target. It compiles, but it won't launch the GUI window. The `.xcodeproj` is the one configured as a proper macOS application bundle.


---

## Fitting Stuff in a Metal Box (1590B Enclosure Planning)

At some point the software has to connect to actual hardware, and that means drilling holes in an aluminum box and fitting connectors into them. Sounds simple. It requires more math than you'd think.

### The 1590B Is Smaller Than It Looks

The Hammond 1590B — a standard guitar pedal enclosure — measures 112mm × 60mm × 31mm on the outside. The *side panels* (the long faces where you drill jacks) are only **112mm wide and 31mm tall**. That's roughly the size of a Snickers bar standing on its edge.

Now consider: a 5-pin DIN MIDI connector needs a **16mm hole**. That means its center has to be at least 8mm from any edge — leaving you only 15mm of comfortable vertical space in a 31mm panel. It physically fits, but just barely. Now try fitting two of them side-by-side with a 24mm center-to-center gap... you're doing connector Tetris.

**The lesson**: Before you drill anything, do the spacing math. For each connector:
- Find the hole diameter → divide by 2 → that's your minimum edge clearance
- Add ~2mm for material strength (you don't want a thin sliver of aluminum at the edge)
- Calculate center-to-center spacing: the sum of both connectors' "personal space bubbles"

### Active vs Passive MIDI Thru

MIDI was designed in 1983 and uses a **current loop** — the transmitting device pushes a 5mA signal through the cable and into an optocoupler in the receiving device. The receiver is completely isolated from the transmitter electrically. It's elegant.

A **MIDI Thru** jack just passes the incoming signal back out again. There are two ways to do this:

**Passive Thru**: Literally just wire the incoming pins to a second DIN connector. No components, no power. The same current loop drives both. Works perfectly for one thru output. This is what we're building.

**Active (Buffered) Thru**: Routes the signal through an op-amp that re-drives each output independently. Requires power (~5V), but each output is isolated and properly driven. Useful if you're splitting to 4+ devices and worried about signal degradation.

For a single thru output going to one more pedal? Passive is all you need. Two wires. Done.

### Thinking About Cable Routing First

The layout decision that mattered most wasn't "what fits?" — it was "where do I want cables coming out?"

On a pedalboard, TRS cables run to pedals (forward/sideways). The MIDI input cable runs back to the Pi/interface. If everything exits from the same face, you get a cable spaghetti nightmare at that corner of the board.

**Option B** — the one we picked — separates the cable types:
- **Long side**: all 4 TRS outputs (cables go toward pedals)
- **Short side**: both DIN connectors (MIDI cable runs toward the Pi setup)
- **Top face**: SPDT config switches (no cables, just finger access)

The cables exit in two different directions from perpendicular faces. On a pedalboard this reads as "organized." The switches on top are accessible without unplugging anything.

**The meta-lesson**: When planning physical hardware, ask "where do cables go?" before "what fits?" The mechanical constraints are usually solvable — the routing is what determines whether the finished thing is annoying to live with.

---

## Session 14: Lessons — Layouts, Keyboards, and Invisible Bugs

### The LED That Was Moving Furniture

Picture a haunted house where a ghost keeps rearranging your living room furniture — but only when the lights turn on. That was basically the LED bug.

When an LED activated, the logo above it and the bat switches below it would physically shift upward. Infuriating. The cause was subtle: the glow effect (a blurred circle, ~16px wide) lived *inside* a ZStack with the 9px LED dot. In SwiftUI, a ZStack sizes itself to fit its **largest child**. So the moment the 16px glow appeared, the entire ZStack grew to 16px, nudging everything around it.

The fix: move the glow to `.background()`. Here's the key insight — SwiftUI's `.background` modifier renders content behind a view **without affecting its layout size**. The LED dot stays 9px in the layout; the glow just paints behind it in the same space. Zero layout impact.

```swift
.frame(width: 9, height: 9)          // layout is always 9×9
.background(                          // glow paints here — layout ignores it
    Circle().fill(c.opacity(0.40))
        .frame(width: 16, height: 16).blur(radius: 4)
)
```

This is one of those SwiftUI gotchas that's completely non-obvious until you know it: **ZStack = layout aware, .background = layout invisible**.

### Building a Piano Keyboard: It's All About the Math

A piano keyboard is a surprisingly geometry-heavy problem. The tricky part isn't the white keys — those are evenly spaced. It's the black keys that float *between* white keys at very specific positions.

The formula for where a black key goes:
```
x position = (leftAdjacentWhiteKeyIndex + 1) × whiteKeyWidth - blackKeyWidth / 2
```

That `(leftAdjacentWhiteKeyIndex + 1)` is the *right edge* of the white key to the left. Then you back up half a black key width to center it in the gap. It's like placing a bookmark between two pages — the bookmark's center sits at the gap between pages.

The Mac keyboard mapping follows GarageBand conventions so your muscle memory from GarageBand works here:
- `A S D F G H J` = C D E F G A B (white keys, home row)
- `W E T Y U` = C# D# F# G# A# (black keys, top row)
- `Z / X` = octave down / octave up

For keyboard input on macOS 14+, the pattern is `@FocusState` + `.focusable()` + `.onKeyPress(phases: [.down, .up])`. The `.down` fires Note On, `.up` fires Note Off. Using `phases: [.down, .up]` on a single modifier is cleaner than two separate handlers.

### The RunLoop Trap with Hold-to-Activate

Both the Reset-to-Stock button and the Factory Reset button use a "hold 2 seconds" pattern — you hold the mouse button and a red progress bar fills up. When it completes, a confirmation alert appears. Two deliberate actions = accidentally nuking your presets requires extraordinary effort.

The implementation uses a `Timer` that fires every 1/30 second (30fps), updating `holdProgress` from 0 to 1. The crucial detail: add the timer to `RunLoop.main` with mode `.common`:

```swift
RunLoop.main.add(timer, forMode: .common)
```

Why `.common`? When you hold a mouse button, macOS enters a *tracking* run loop mode that blocks the **default** mode. A timer added to `.default` would just... stop firing while you're pressing. `.common` is a set of modes that includes tracking, so the timer keeps ticking no matter what the user's hands are doing. Without this, the progress bar would freeze the moment you started holding.

### When Your Data Model Determines Your UI

One elegant pattern this session: the parameter *definition* (in `MoodMKIIDefinition.swift`) now directly controls which UI widget renders. Clock Div has 8 options? That's `type: .toggle(options: [...])` with 8 items, which triggers `SteppedPickerView` (the indexed row of tappable segments). Octave Transpose has 9? Same deal.

The rule implemented in `needsFullWidth()`:
- `ramping_waveform` → always full-width (special waveform picker)
- `factory_reset` → always full-width (big red button)
- `.toggle` with **more than 4** options → full-width stepped picker
- `.toggle` with ≤4 options → regular segmented control (fits in 2-column grid)

The model knows what the data is; the view knows how to render given the count. Clean separation.

---

## Session 15 — How "One Codebase, Two Platforms" Actually Works

### The Big Idea: Conditional Compilation

You've probably seen `#if DEBUG` in Swift to include debug-only code. This session used the same trick at a larger scale with `#if os(macOS)` and `#if os(iOS)`. The Swift compiler literally throws away the other platform's code when building — so the iOS build never sees any AppKit, and the macOS build never sees any UIKit.

This is the opposite approach from trying to write code that works everywhere. Instead of a universal API, you write *both versions* right next to each other and let the compiler pick:

```swift
#if os(macOS)
Color(nsColor: .controlBackgroundColor)
#else
Color(.secondarySystemBackground)
#endif
```

AppKit and UIKit have different APIs for system colors, fonts, views — almost everything. Conditional compilation gives you a clean way to handle all of that without duplicating files.

### One Source Folder, Two Targets

The biggest architectural choice: should iOS have its own separate folder of Swift files? We went with **no** — same `Sources/MIDIControl/` folder powers both targets. This means:

- Bug fixes and new features automatically apply to both platforms
- No "I updated macOS but forgot iOS" drift
- New files just work on both unless you guard them with `#if os(iOS)`

The tradeoff: every file *must* compile for both platforms. That's why we had to wrap things like `NSWindow.allowsAutomaticWindowTabbing` — iOS doesn't have `NSWindow`, and the compiler will error out if it sees it in an iOS build.

### xcodegen: The Project File Generator

Xcode projects are defined by a `.xcodeproj` file — which is actually a directory full of XML-like plists. They're huge, fragile, and a nightmare to hand-edit. xcodegen solves this by letting you define your project in a clean `project.yml` file and *generating* the `.xcodeproj` from it.

Adding the iOS target was just adding a new section to `project.yml`. One `xcodegen generate` command and Xcode gained a second target pointing at the same source folder with different platform settings. This is one of those tools that feels like cheating once you know about it.

### CABTMIDICentralViewController: Apple's Built-In Bluetooth MIDI UI

CoreAudioKit ships a ready-made view controller (`CABTMIDICentralViewController`) that handles the entire Bluetooth MIDI pairing flow: scanning, connecting, naming devices. You just present it. Once a device pairs, CoreMIDI automatically adds it as a destination — our existing `MIDIManager.refreshDestinations()` picks it up for free via the setup-changed notification that was already wired.

This is a great example of the Apple platform advantage: the plumbing for MIDI over Bluetooth already exists in the OS. You don't have to implement BLE scanning, pairing dialogs, or MIDI-over-BLE framing. Just present one view controller.

### The Ghost Knob

When you load a preset, all knobs snap to the preset's values. But as soon as you start twiddling a knob live, how do you know where the preset was? You've lost your reference point.

The ghost knob solves this by keeping a faint dashed arc showing the last-loaded preset position while the live arc moves. It's the same idea as "before and after" — you can see both simultaneously.

Implementation was clean: `PedalViewModel` got a `ghostValues: [Int: Int]` dictionary (keyed by CC number, same as everything else). `loadPreset` saves the preset's parameters there. `RotaryKnob` draws the ghost arc whenever `savedValue != displayValue`. Reset clears it back to nil, which hides the arc.

The dashed stroke style is what makes it read as "reference" rather than "active":
```swift
StrokeStyle(lineWidth: 3.0, lineCap: .round, dash: [3, 5])
```
Three pixels on, five pixels off — subtle but visible once you know to look.

---

## Session 16: Making One App Work on Every Screen Size

### The iOS Size Class Trap

SwiftUI gives you `horizontalSizeClass` and `verticalSizeClass` as environment values to detect screen form factors. Sounds great. Here's the trap: **on iPad, both are `.regular` in portrait AND landscape.** So if you check `horizontalSizeClass == .regular` to mean "iPad", you can't then distinguish between iPad portrait and iPad landscape.

The fix for iPad orientation: use `GeometryReader` and compare `width > height` directly. No magic environment — just geometry. If the screen is wider than it is tall, it's landscape.

iPhone landscape is different: `verticalSizeClass == .compact` correctly fires when an iPhone rotates. So:
- iPad orientation → `GeometryReader { geo in geo.size.width > geo.size.height }`
- iPhone landscape → `@Environment(\.verticalSizeClass) == .compact`

### scaleEffect + Double Frame = Responsive Enclosure

The pedal enclosure was designed at fixed 280×500 points — all the proportions, knob sizes, and spacing are hardcoded. Making it responsive without rewriting everything uses a SwiftUI trick:

```swift
.frame(width: 280, height: 500)      // 1. lay out at natural size
.scaleEffect(scale)                   // 2. visually shrink the rendered output
.frame(width: 280 * scale, height: 500 * scale)  // 3. tell layout the new size
```

Step 1 tells the internal content "you have 280×500 to work with." Step 2 is like CSS `transform: scale()` — it shrinks the pixels but SwiftUI's layout engine still thinks the view is 280×500. Step 3 overrides that — it tells SwiftUI "actually, only reserve this much space." Surrounding views see the scaled size. The enclosure renders sharp because it's drawn at full resolution then scaled down by the GPU.

The scale factor comes from `GeometryReader`: divide the available height by the enclosure height, cap at 1.0 so we never upscale. `min(1.0, geo.size.height * 0.75 / 500)`.

### Navigation Bar as Prime Real Estate

The nav bar is always there — you need it for the toolbar buttons. Leaving it occupied only by a title is a waste of space. SwiftUI's `.principal` toolbar placement puts any view in the center of the navigation bar, replacing the title.

```swift
ToolbarItem(placement: .principal) {
    Picker("Pedal", selection: $selectedIndex) { ... }
        .pickerStyle(.segmented)
        .frame(maxWidth: 220)
}
```

This moved the pedal picker from its own row (with padding, ~48pt total) into the existing nav bar, saving ~48pt of vertical space on an already-crowded iPhone screen. The MIDI and Presets buttons stay in `.navigationBarTrailing` — all three controls live in the same bar.

### Landscape on iPhone: Think Columns, Not Rows

Portrait mode is for scrolling vertically — the phone is tall and narrow. Landscape flips that: you have more width but almost no height (maybe 330pt usable). A vertical scroll with a 500pt enclosure doesn't work.

The solution is a **two-column HStack**: enclosure on the left (scaled to fit the available height), controls scrollable on the right. This is the same pattern as macOS's HSplitView, just without the adjustable divider. One divider, two regions, everything fits.

```swift
HStack(alignment: .center, spacing: 0) {
    VStack {
        Spacer()
        PedalEnclosure(..., scale: scale)
        Spacer()
    }
    .frame(width: enclosureWidth * scale + 12)
    
    Divider()
    
    ScrollView {
        // channel bar, dip switches, advanced settings
    }
}
```

The key insight: don't fight the screen shape. Portrait = tall → stack vertically. Landscape = wide → split horizontally. Match your layout to the constraint.

---

## Session 17: Getting Your App Onto a Real iPhone (Free, No App Store)

### The Two Tiers of Apple Development

Before you can put an app on a phone, you need to understand Apple's two development tiers:

| | Free (Personal Team) | Paid ($99/year) |
|---|---|---|
| Install on your own device | ✅ | ✅ |
| App Store submission | ❌ | ✅ |
| TestFlight beta sharing | ❌ | ✅ |
| App expires after | 7 days | 1 year |

The **free personal team** is an Apple ID you already have — no enrollment, no credit card. The restriction is that apps re-expire every 7 days and can only run on devices you physically connect to Xcode. For personal use and testing, it's completely fine.

### What "Code Signing" Actually Is

When you install an app on an iPhone, iOS needs to know it came from someone Apple can trace. That "someone" is a **signing certificate** — a cryptographic identity Xcode generates and stores in your Mac's Keychain. Every app binary gets signed with your cert before it lands on the device.

When Xcode says "codesign wants to access key Apple Development: Your Name in your keychain" and asks for your Mac login password — that's it unlocking the Keychain to use your cert. It's not a virus, it's not sketchy, it's exactly supposed to happen. You'll see it once per new cert, then never again.

### Developer Mode on iOS (iOS 16+)

Apple introduced a **Developer Mode** lock in iOS 16 as a security measure. Before you can run a dev-signed app on your device, you have to explicitly unlock this mode. It's a one-time step per device.

**How to enable it:**
1. Connect your iPhone to your Mac via USB
2. Hit Play in Xcode — it'll attempt to install and fail with a prompt
3. On your iPhone: **Settings → Privacy & Security → Developer Mode → toggle ON**
4. iPhone restarts
5. After restart, a system prompt appears: "Turn On Developer Mode?" → **Turn On**
6. Back in Xcode, hit Play again — installs successfully

Why the restart? Because Developer Mode changes how iOS's security kernel handles app signatures — it's not just a preferences flag, it's a kernel-level change that requires a clean boot to activate.

### The Full First-Time Setup Flow

Here's the complete end-to-end for a brand-new Mac + iPhone pairing:

1. **In Xcode → Settings → Accounts** — add your Apple ID if not already there
2. **In Xcode project → target → Signing & Capabilities** — set Team to "Your Name (Personal Team)"
3. Xcode auto-generates a provisioning profile (takes ~5 seconds, no action needed)
4. **Mac Keychain prompt** — enter your Mac login password to allow codesign access
5. **Connect iPhone via USB** — iPhone prompts "Trust This Computer?" → tap **Trust**, enter passcode
6. **Enable Developer Mode** on iPhone (Settings → Privacy & Security → Developer Mode)
7. Select your device in Xcode's run destination dropdown
8. Hit **▶ Play** — app builds and installs
9. **First launch on device**: Settings → General → VPN & Device Management → your Apple ID → **Trust**

Step 9 is the "trust the developer" step — iOS defaults to blocking apps from unrecognized sources even after install. You have to manually trust your own certificate. Once trusted, all future apps signed with the same cert install and launch without this step.

### The 7-Day Expiry Reality

With a free account, the provisioning profile that authorizes your app expires after 7 days. The app itself doesn't disappear from your phone, but iOS will refuse to launch it — you'll see "app is no longer available" or similar.

The fix: plug in to Xcode and hit Play again. Xcode re-signs the app and resets the 7-day clock. The app data (presets, settings) survives — it's just the authorization that expires.

### Why You Don't Need the App Store for Personal Use

The whole App Store process — review, provisioning, certificates, screenshots, descriptions — exists for public distribution. For an app you're building for yourself to control your own guitar pedals, none of that matters. The personal team + Xcode flow gives you a real, fully functional native app on your real device. It's what every iOS developer uses during development anyway.

The only difference between a "dev build" and an "App Store build" is who signed it and where it came from. The code is identical.

---

## The Phantom Footswitch: How Two Pedals on the Same MIDI Channel Will Drive You Crazy

Picture this: you're adjusting the Time knob on the MOOD MKII, and the Brothers AM footswitch LED randomly flips on or off. You're not touching the Brothers at all. What the heck?

This is called **MIDI channel crosstalk**, and it's one of those bugs that makes you feel like your hardware is haunted before you realize it's a very logical (if maddening) software mistake.

### The Setup

Both Chase Bliss pedals share an overlapping CC table. CC 14 means "Time" on the MOOD but "something else" on the Brothers. CC 102 and 103 are footswitch triggers on the Brothers. That's why Chase Bliss designed the pedals to operate on **different MIDI channels** — so they can share CC numbers without interfering.

The app was supposed to default Brothers AM to ch2, MOOD MKII to ch3. But `MoodMKIIDefinition.swift` had `defaultChannel: 2` — same as Brothers. The hardware didn't care which app sent the message. Both physical pedals were listening on ch2, so they both responded to every CC.

When you turned the MOOD Time knob, the app sent CC 14 on ch2. The Brothers heard that. Depending on what CC 14 does on the Brothers hardware at that value, the pedal might have interpreted it as a footswitch state change. Phantom toggles.

### The Memory Bug That Made It Worse

Even if you caught this and used the channel-change UI to move MOOD to ch3, it wouldn't survive a restart. The `midiChannel` property was just an `@Published var` — pure in-memory runtime state. Relaunch the app, both pedals reset to their `defaultChannel` values, both back on ch2, chaos resumes.

The fix was two-pronged:
1. **Correct the default** — MOOD MKII now ships with `defaultChannel: 3`
2. **Persist the selection** — `UserDefaults.standard.set(midiChannel, forKey: "pedal_\(definition.id)_midiChannel")` in the `didSet` observer. One line. Now your channel choice survives restarts, and a preset load that changes the channel also persists it automatically.

### The Black Bars That Weren't a Layout Problem

The app was showing big black bars at the top and bottom on iPhone 16 Pro. The natural instinct is to dig into SwiftUI layout — maybe a VStack isn't expanding, maybe GeometryReader is reporting wrong values. We spent time investigating that.

The actual fix was one line in `project.yml`:
```yaml
UILaunchScreen: {}
```

Here's why: iOS uses the presence of a launch screen as a **signal of intent**. When an app declares `UILaunchScreen`, it's telling the OS "I was explicitly built for modern full-screen devices." Without that declaration, iOS assumes the app might have been designed for an older, smaller screen — maybe an iPhone 4 or 5 — and it letterboxes it with black bars to be "safe."

This has nothing to do with SwiftUI layout code. The OS makes this decision before your first line of Swift runs. It's a metadata problem, not a rendering problem. The `{}` empty dict is enough — you don't need custom branding on the launch screen, just the key's presence.

**Lesson:** If you see black bars at top and bottom on a real iOS device and not the simulator, check `UILaunchScreen` before touching any layout code.

---

## Session 19: The Wrong-Channel Factory Preset Bug

### "I thought you already fixed the crossover bug?"

We did — in session 18, we fixed the `defaultChannel` in `MoodMKIIDefinition.swift` so MOOD ships on ch3 instead of ch2. But this session Bryan reported the same symptom was *still happening*: clicking a MOOD preset would physically snap Brothers AM's toggles and change its knob values.

The `defaultChannel` fix was right. But there was a second, separate bug hiding in a different place.

### Where a Preset Stores Its Channel

When you save a preset, it captures the current `midiChannel` along with all the knob and toggle values. The `Preset` struct has a `midiChannel: Int` field, and `savePreset()` writes whatever the VM's current channel is at save time.

The **factory presets** in `FactoryPresets.swift` are hardcoded Swift structs. Someone (me, in session 17 or 18) wrote all 6 MOOD MKII factory presets with `midiChannel: 2`. Just a typo in the source code. The definition was correct (`defaultChannel: 3`), but the factory presets were wrong.

### Why the Wrong Channel Is So Destructive

Here's the sequence when you click a MOOD preset:

1. `loadPreset()` runs
2. `midiChannel = preset.midiChannel` → MOOD's app channel becomes **2** (Brothers' channel)
3. `sendAll()` fires → every MOOD CC value goes out on channel **2**
4. Brothers AM hardware is listening on ch2 → it receives all of them
5. MOOD's CC 21 is Wet Channel (Reverb/Delay/Slip). Brothers' CC 21 is Gain 2 Type. Brothers receives whatever value MOOD had for Wet Channel and interprets it as a Gain 2 Type change. Toggle physically snaps.
6. Same for CC 22, CC 23, and all the knob CCs

After loading, the MOOD PedalViewModel *also* thinks it's on ch2. So any manual MOOD adjustment you make afterward *also* goes to Brothers. The pedals are fully crossed.

### The Migration Problem

You can't just fix the Swift source code and ship it, because users who already launched the app once will have the wrong-channel presets saved to disk as JSON files. The next app launch loads from disk, not from the factory preset structs.

The fix needed two parts:
1. **Source fix** — Correct all 6 presets in `FactoryPresets.swift`: `midiChannel: 2` → `midiChannel: 3`, and bump the seed version so they're re-seeded.
2. **Migration** — A one-time function that scans all MOOD MKII presets on disk and corrects any with `midiChannel == 2`. Runs once at app launch, gated by a UserDefaults key.

The migration is intentionally scoped: it only touches MOOD presets, and only ones with channel 2. Brothers presets *should* have channel 2, so they're untouched.

### The Bonus Bug: Additive Preset Loading

While we were in `PedalState`, we noticed `loadValues()` was *additive* — it only wrote CC values that were present in the preset dict. If the current state had CC 71 = 127 (Hi Gain ON), and you loaded a preset that didn't mention CC 71, the Hi Gain stayed on even though the preset never intended it.

This is bad for the same reason a fill-in-the-blank answer is worse than multiple choice: the preset should represent a *complete known state*, not a partial delta. The fix was simple: reset all params to factory defaults first, then overlay the preset values. Now a loaded preset means exactly what it says.

### The Lesson

**Factory presets are data, not code.** They look like code — they're Swift structs in a `.swift` file — but they carry data that gets saved to disk and must be migrated like a database schema. A typo in a factory preset isn't just a visual glitch you'll notice on first launch and fix by opening the source. It's a seed that plants wrong data on disk, survives app updates, and requires a migration to correct. Treat hardcoded data with the same care you'd give a database migration.

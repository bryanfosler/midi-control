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

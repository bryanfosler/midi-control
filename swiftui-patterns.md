# SwiftUI / macOS / iOS Patterns (Hard-Won)

Collected from MIDI Control and ClawDeck development. Read this file when working on SwiftUI code.

## State & Observation
- **`PedalState` is a CLASS** — mutations to `state.values` fire `state.objectWillChange` but NOT `viewModel.objectWillChange`. Fix: Combine forwarding in PedalViewModel init: `state.objectWillChange.sink { self?.objectWillChange.send() }`
- **Interactive controls** use `@State var liveValue/liveIndex` for instant visual feedback; synced back from binding via `onAppear` + `onChange(of:)`
- **SwiftData writes must be `@MainActor`** — hand off from background actor using `Task { @MainActor in ... }`
- **AsyncStream is single-consumer** — don't share one stream across multiple ViewModels; use fan-out

## Gestures & Hit Testing
- **Gesture coordinate space**: always use `coordinateSpace: .local` so `startLocation.x/y` is relative to the view (0…width), not screen-absolute
- **`Color.clear` doesn't hit-test on macOS** — use `Color.white.opacity(0.001)` for invisible tap targets
- **`DragGesture(minimumDistance: 0, coordinateSpace: .local)`** is the reliable tap+drag pattern on macOS
- **`.contentShape(Rectangle())` for full-width button tap area** — with `.buttonStyle(.plain)`, hit testing is delegated to the label's rendered content; `Spacer()` is transparent. Fix: put `.contentShape(Rectangle())` on the `HStack` **inside** the label, not on the outer `Button`
- **SwipeableMessageRow gesture** — must use `.simultaneousGesture()` not `.gesture()` — exclusive gestures eat ScrollView's pan. Use `minimumDistance: 30` and require `horizontal > vertical * 2.5`
- **`scrollDismissesKeyboard` + `simultaneousGesture` conflict** — adding `.simultaneousGesture()` to a `ScrollView` suppresses the built-in keyboard dismiss gesture. Always add `.scrollDismissesKeyboard(.interactively)` on the same `ScrollView`

## Layout & Views
- **`.background` vs ZStack for decorative layers** — `.background` is layout-invisible (won't shift surrounding views); ZStack sizes to its largest child
- **`.principal` toolbar placement** — puts any view in the nav bar center (replaces title)
- **Responsive enclosure scaling** — `scaleEffect(s)` + double `.frame` trick: first frame at natural size, scaleEffect shrinks rendering, second frame tells layout the scaled size
- **Tooltips (`.help()`)**: must be on the **innermost interactive view** (same layer as gesture), not a parent container

## Platform-Specific
- **Timer during mouse-hold** — add to `RunLoop.main` with mode `.common`; tracking mode blocks `.default` timers
- **Keyboard piano input** — `@FocusState` + `.focusable()` + `.onKeyPress(phases: [.down, .up])` on macOS 14+
- **iPad orientation detection** — size classes are `.regular` in BOTH portrait and landscape; use `GeometryReader { geo in geo.size.width > geo.size.height }`
- **iPhone landscape** — `verticalSizeClass == .compact` correctly identifies iPhone landscape
- **iOS Simulator type-checker timeout** — complex inline expressions in a single view body can time out on x86_64 simulator builds. Fix: extract to computed properties
- **`secondarySystemBackground` is UIKit-only** — not available on macOS. Use `Color(nsColor: .controlBackgroundColor)` instead

## Navigation
- **NavigationSplitView on iPhone is a stack, not a drawer** — `columnVisibility` binding doesn't work for programmatic sidebar toggling when starting in `.detailOnly`. Use a custom ZStack overlay for left-drawer UX on iPhone
- **List `selection:` binding swallows NavigationLink taps on iPhone** — don't use `selection:` on Lists with NavigationLinks on iPhone; it's meant for iPad/Mac sidebar multi-select

## SwiftData
- **SwiftData + multiple macOS scenes** — `Settings {}` scene needs `.modelContainer(container)` explicitly; it does NOT inherit from `WindowGroup`
- **GSD phase directories live in workstream** — `.planning/workstreams/milestone/phases/` NOT `.planning/phases/`
- **macOS Settings TabView toolbar** — `.toolbar` in child tab views bubbles up to the window toolbar. Use inline `HStack` inside Form sections instead

## watchOS
- **WCSession activation is async** — always set `session.delegate = self` BEFORE `session.activate()`. Never read `isReachable`/`isCompanionAppInstalled` before `activationDidCompleteWith` fires
- **WCSession delegate collision** — only one class should be `WCSession.default.delegate`. Use callback registration pattern if multiple classes need to react
- **watchOS TextFieldLink** — `.buttonStyle(.plain)` breaks tap activation

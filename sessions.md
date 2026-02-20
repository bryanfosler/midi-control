# Session Log — MIDIControl (Chase Bliss MIDI Controller)

*Tracks each working session: what we did, how long it took, what shipped, what's next.*

---

## Session 1 — Phase 1 MVP Build

**Date:** 02.16.2026
**Time spent:** ~45m

### What We Built
- Full project scaffolding (Swift Package, macOS 14+, SwiftUI)
- Pedal definition system — `PedalDefinition`, `ParameterDefinition` with 4 parameter types (knob, toggle, dipSwitch, footswitch)
- Complete Brothers AM CC table (8 knobs, 3 toggles, 15 dip switches, 2 footswitches, expression)
- Complete MOOD MKII CC table (7 knobs, 6 hidden options, 6 toggles, 6 footswitches, synth mode ADSR, 16 dip switches, misc controls)
- CoreMIDI manager with device enumeration, hot-plug notifications, CC/PC sending
- MVVM architecture — `PedalViewModel` (per-pedal state + real-time MIDI sending), `AppViewModel` (app-level state)
- Full SwiftUI UI — `ContentView` with toolbar, `PedalView` with dynamic section rendering, `PresetPanel` sidebar
- Reusable components — `KnobSlider`, `ToggleSwitch`, `DipSwitchBank`, `BypassButton`, `MomentaryButton`
- Preset storage (JSON files in App Support)
- Project docs (`CLAUDE.md`, `bryanlearns.md`)

### What Shipped
- 21 source files, compiles cleanly on first build
- Ready to open in Xcode and run as a native macOS app

### Decisions Made
- Pedal definitions hardcoded in Swift (type-safe, no JSON parsing for MVP)
- Real-time CC sending (on every slider change, not on-release)
- Individual JSON files per preset in `~/Library/Application Support/MIDIControl/presets/`
- Both pedals share one MIDI output, differentiated by channel
- MVVM architecture for iOS portability later
- macOS 14+ minimum (for modern SwiftUI APIs)

---

## Session 2 — GitHub, Notion & Time Tracking Infrastructure

**Date:** 02.17.2026
**Time spent:** ~35m

### What We Built
- GitHub repo (`bryanfosler/midi-control`) with initial commit + .gitignore
- GitHub Project board for MIDI Control
- GitHub Actions → Notion sync workflow with Project tagging
- Time tracking via issue comments (`Time: 45m` → syncs to Notion "Time Spent (min)" column)
- Updated route-generator workflow to match (Project tag + time tracking + inline database ID)
- 8 GitHub issues (6 backlog + 2 completed)
- Time logging instructions doc
- Master `CLAUDE.md` updated with session & time tracking requirements

### What Shipped
- Repo: https://github.com/bryanfosler/midi-control
- GitHub Project: https://github.com/users/bryanfosler/projects/2
- Both projects syncing to shared Notion database with Project tags and time tracking

### Bugs Fixed
- Notion API key was empty on first deploy — re-set secret
- GitHub Actions secret masking corrupted database ID — inlined UUID in workflow
- Workflow lacked `issues: read` permission for fetching comments — added permissions block
- "Time Spent (min)" property didn't exist in Notion — created manually

### Decisions Made
- Separate GitHub Projects per repo (not one shared board)
- Time tracked as numeric minutes in Notion for easy summing across projects
- Comment-based time logging (`Time: Xm`) over labels or manual entry
- Database ID inlined in workflow (not sensitive, avoids masking bug)
- Session & time tracking instructions added to master CLAUDE.md for all future sessions

---

## Session 3 — Xcode Migration + Realistic Pedal UI Redesign

**Date:** 02.18.2026
**Time spent:** ~1h 30m

### What We Built
- Migrated from Swift Package to proper `MIDIControl.xcodeproj` via xcodegen + `project.yml` (fixes blank window / missing bundle ID)
- Complete visual redesign of both pedal enclosures based on reference photos of real Chase Bliss pedals:
  - Fixed both pedals to identical 280×500pt size
  - Correct colors: MOOD MK2 = deep violet + white outer border; Brothers AM = deep purple/plum (was wrongly cream/gold)
  - Accurate 3+3 knob layout for both pedals; toggles now render below knobs (matching real hardware)
  - `MoodBrand` — horizontal amber/yellow color bands + large italic "MOOD MKii" text
  - `BrothersBrand` — gold sunburst "AM" badge + large serif "Brothers" text on dark background
  - Corner screws, gradient enclosure shell, thin separator rules
- `DipSwitchPanel.swift` — new collapsible panel above the pedal (represents physical side panel)
- Scroll wheel support on all rotary knobs (`NSViewRepresentable` overlay captures `scrollWheel` events)
- Fixed ForEach duplicate ID bug in ScrewCorners

### What Shipped
- App builds and runs as a proper macOS app bundle — no more blank window
- Both pedals visually close to the Chase Bliss Presets app reference
- All knob interactions: drag up/down, scroll wheel, Shift for fine control, Option+click to reset

### Bugs Fixed
- **Blank window / missing bundle identifier** — Swift Package doesn't create app bundle; fixed by generating `.xcodeproj` with xcodegen
- **ForEach duplicate ID** in `ScrewCorners` — corner points share same x value; fixed to use `pts.indices`
- **Brothers AM wrong colors** — was cream/gold from original code; corrected to deep purple/plum from reference photos

### Decisions Made
- xcodegen + `project.yml` as the build system going forward (not Swift Package)
- Dip switches live in a separate collapsible panel above the pedal (not on the enclosure face)
- Scroll wheel sensitivity: 2 CC/tick normal, 0.5 CC/tick with Shift held

---

## Session 4 — Wrap-Up Skill Setup

**Date:** 02.18.2026
**Time spent:** ~20m

### What We Built
- Installed the `/wrap-up` skill from a Reddit post into `~/.claude/skills/wrap-up/SKILL.md`
- Fully customized it for Bryan's workspace: hardcoded repo paths, sessions.md format, bryanlearns.md update step, GitHub time tracking workflow, xcodegen reminder for MIDI Control, and Drafts folder for publish drafts
- Synced to legacy `~/Documents/Claude/Commands/wrap-up.md`
- Created `~/Documents/Claude/Drafts/` folder
- Added Skills section to global `CLAUDE.md` (restart required to activate new skills)

### What Shipped
- `/wrap-up` skill ready to use — activate by restarting Claude Code

### Decisions Made
- Skills live in `~/.claude/skills/`, not `~/Documents/Claude/Commands/` (legacy)
- Commands folder kept in sync as a backup reference

---

## Session 5 — Lifelike UI, Correct Dip Switches, 12 Brothers AM Presets

**Date:** 02.19.2026
**Time spent:** ~1h 30m

### What We Built
- `RotaryKnob.swift` — redesigned with 3D dome rendering (bevel ring, grip ticks, radial gradient dome, specular highlight); smoother drag/scroll (5px/unit drag, scroll accumulator for trackpad); Shift for fine control
- `ToggleSwitch3Way.swift` — rewrote as horizontal metal bat switch (labels above, chrome bat slides left/center/right, spring animation); fixed broken tap interaction (macOS `Color.clear` doesn't hit-test — replaced with `Color.white.opacity(0.001)`)
- `DipSwitchBank.swift` — 3D housing with shadow, slide tab, LED dot, `pedalId` wired through
- `BypassButton` / `MomentaryButton` — rubber ring, radial gradient dome, lens LED, `pedalId` wired through
- `ParameterDescriptions.swift` (new) — hover tooltips for every parameter on both pedals, sourced from PDF manuals; lookup priority: pedal+id → pedal+cc → global
- `BrothersAMDefinition.swift` — fully corrected dip switch definitions (both banks, all 16 switches) per official MIDI manual
- `PedalLayout.swift` — Brothers AM dip banks updated to correct IDs (`dip_vol1`–`dip_polarity`, `dip_hi_gain_1`–`dip_bank`) and labels ("Control (Exp & Ramp)" / "Customize")
- `FactoryPresets.swift` (new) — 12 Brothers AM presets seeded on first launch (bumped seed key to v2 for re-seed)
  - Factory: The Analog Man, Sunny Skies, 2-In-1, Bad Bros
  - Two-Channel Ideas: Clean/Dirty, Amp Pusher
  - Stacking Ideas: Overloader, Expander, Combo
  - Treble Booster Settings: Cutting Cleans, Full Stack, Lifted Distortion

### What Shipped
- All 12 presets verified seeded and named correctly at runtime
- `swift build` clean (Build complete 3.50s)
- Commit: `394ce18`

### Bugs Fixed
- **Toggle switches not clicking** — macOS `Color.clear` is transparent to hit-testing; replaced with `Color.white.opacity(0.001)` which is invisible but receives mouse events
- **Brothers AM dip switches completely wrong** — original code had wrong names and functions for both banks; replaced with correct IDs/names per MIDI manual
- **Tooltip warnings on dip switches** — CC-based fallback keys replaced with proper ID-based keys now that labels are correct; removed all ⚠️ warnings

### Decisions Made
- Factory preset seeding uses UserDefaults key versioning (`v1` → `v2`) so existing users automatically get new presets on next launch
- Tooltips use three-level lookup (pedal+id → pedal+cc → global) as a safety net for future parameter additions
- `Color.white.opacity(0.001)` is the standard macOS SwiftUI workaround for invisible hit-testable tap areas

---

## Session 6 — Global Utils Setup + ProgressTracker (Python/JS/Swift)

**Date:** 02.19.2026
**Time spent:** ~35m

### What We Built
- `~/utils/` shared utilities folder — available to all projects on the machine
- `progress_tracker.py` — terminal progress bar with elapsed time and ETA for Python scripts
- `progress-tracker.js` — same for Node.js (terminal) and browser (renders HTML progress bar)
- `ProgressTracker.swift` — same for Swift, packaged as a local SPM library
- `~/utils/CLAUDE.md` — documents all utilities so Claude Code always knows they exist
- Shell config (`~/.zshrc`) updated with `PYTHONPATH`, `NODE_PATH`, and `~/.npm-global` PATH
- npm prefix moved to `~/.npm-global` (was system-owned `/usr/local`, blocked npm link)
- `~/utils` initialized as a git repo and pushed to https://github.com/bryanfosler/utils (private)
- ProgressTracker added to MIDIControl as a local SPM dependency (`Package.swift`)

### What Shipped
- All three imports verified working in a fresh shell
- `swift build` clean after adding SPM dependency
- GitHub: https://github.com/bryanfosler/utils

### Bugs Fixed
- `npm link` permission denied on `/usr/local` — fixed by setting npm prefix to `~/.npm-global`
- SPM product reference — SPM identifies local packages by folder name ("swift"), not Package.swift `name` field; fixed with `.product(name: "ProgressTracker", package: "swift")`

### Decisions Made
- Utils live at `~/utils/` (flat, language-separated: python/, js/, swift/)
- npm prefix at `~/.npm-global` going forward (avoids sudo for all future global npm installs)
- ProgressTracker is terminal-only in MIDIControl context — in-app progress uses SwiftUI's native `ProgressView`

---

## Session 7 — UX Overhaul: Controls, Presets & MIDI Channel Management

**Date:** 02.19.2026
**Time spent:** ~2h 30m

### What We Built
- **RotaryKnob** — full rewrite: `DragGesture(.local)` + `@State liveValue` for real-time visual updates; velocity-based acceleration (slow drag = 5px/unit, fast = 1px/unit); click snaps to nearest 10% grid `[0,13,25,38,51,64,76,89,102,114,127]`; fixed left-half click (was broken by `.global` coordinate space bug)
- **ToggleSwitch3Way** — `DragGesture(minimumDistance:0)` on VStack with `.frame(width:trackWidth)` to anchor local coordinate space; `@State liveIndex` for immediate bat animation (same class-mutation fix as knobs)
- **Tooltip fix** — moved `.help()` from outer containers onto the interactive view layer (knobBody ZStack, switchBody ZStack) so macOS tooltip system fires correctly
- **DipSwitch** — housing tinted with `theme.backgroundGradient` colors; label bumped to 9pt medium with drop shadow; panel background more opaque
- **PresetPanel** — shrunk to 140–165px; single-click to load; active preset highlighted with accent border; inline notes removed (shown as hover tooltip); reset-to-defaults button (↺)
- **Combine forwarding** — `state.objectWillChange` forwarded to `viewModel.objectWillChange` so DipSwitchPanel and HiddenSettingsPanel re-render on preset load (hidden features now visible after loading a preset)
- **FactoryPresets** — seed key v4; `cleanupDuplicates()` removes accumulated duplicates; name-based dedup prevents future stacking
- **MIDI channel management** — `setPedalMidiChannel(to:)` sends CC 104 on the current channel then updates app; "Set Channel" sheet with current→new picker, CC 104 explanation, and cross-pedal channel conflict warning
- **ProgressTracker** — integrated into session workflow for multi-step task progress display

### What Shipped
- `swift build` clean (Build complete)
- Commit `e00e955` pushed to `bryanfosler/midi-control`
- Both pedals can now run on separate MIDI channels without cross-talk

### Bugs Fixed
- **Bat switches not clicking** — root cause: `DragGesture(minimumDistance:0)` not previously used; `onTapGesture { location in }` was unreliable on macOS; `DragGesture.onEnded` with `.local` coordinate space is reliable
- **Bat switch visual not updating** — `PedalState` is a class; binding mutations fire `state.objectWillChange` but not `viewModel.objectWillChange`; fixed with `@State liveIndex`
- **Knob left-half click never fired** — `coordinateSpace: .global` made `startLocation.x` a screen-absolute value (always > 29); switching to `.local` fixed it
- **Duplicate presets** — UUID-based file storage + versioned seed keys = new files each seed; fixed with `cleanupDuplicates()` and name-based dedup check
- **Hover tooltips lost** — `.help()` placed on parent container, not the interactive NSView layer; macOS tooltip system needs it on the view that actually receives hover
- **HiddenSettingsPanel stale after preset load** — no Combine forwarding from `state` to `viewModel`; adding it makes all observing views re-render on preset load

### Decisions Made
- `DragGesture(minimumDistance: 0, coordinateSpace: .local)` is the reliable macOS SwiftUI tap+drag pattern — avoids Button hit-testing issues and unreliable `onTapGesture` with location
- `.help()` must be on the **same view** as the gesture for macOS tooltip detection to work
- Combine forwarding (`state.objectWillChange → viewModel.objectWillChange`) is the correct fix for class-based ObservableObject propagation — better than per-view `@State` workarounds for non-interactive views
- CC 104 = Chase Bliss MIDI channel change command; must be sent on the pedal's **current** channel with value = (newChannel − 1)
- Brothers AM and MOOD MKII share 28 overlapping CC numbers — different MIDI channels are **required**, not optional

---

## Backlog / Ideas

*Things mentioned but not built yet:*

- [ ] iOS companion app
- [ ] User-defined pedal definitions (JSON import)
- [ ] MIDI learn mode
- [ ] Sequence/automation recording
- [ ] App icon
- [ ] Keyboard shortcuts for common actions

---

## Session 9 — Visual Polish: Machined Knobs, Realistic Toggles, CB Logo

**Date:** 02.20.2026
**Time spent:** ~1h 30m

### What We Built
- Concentric lathe rings on knob dome tops (Canvas-drawn, simulates CNC-machined aluminum)
- Revised knurling texture: finer crosshatch lines, reduced opacity for realism
- Stronger active-arc glow on knobs (wider bloom + heavier blur)
- Realistic toggle bat behavior: portrait oval that SHIFTS horizontally (no rotation), pivot anchored at center
- Toggle housing enlarged for better proportion
- Chase Bliss logo: replaced `figure.stand` emoji with hand-drawn CBLogoMark (thin ring + "CB" initials)
- AM badge: star changed from filled gold to stroke outline
- Brothers font: switched from serif to .heavy italic (cleaner, more like real pedal)
- 1590B drilling reference added to MIDI converter hardware build guide

### What Shipped
- Committed and pushed: `f08a53b` — all visual changes live on `main`
- GitHub issue #13 created, time logged (1h30m), closed → Notion sync triggered

### Bugs Fixed
- Toggle bat diagonal rotation replaced with correct mechanical pivot behavior
- CB logo was a stock emoji — now a proper drawn lettermark

### Decisions Made
- Toggle bats: perspective is now "portrait oval shifting L/R" not diagonal rotation
- AM star: outline only (not filled), matches Analog Man badge aesthetic
- Brothers font: .heavy italic without serif design is cleaner match to real pedal
- Knurling kept as crosshatch (not concentric rings) on grip ring; dome gets concentric rings

### Outstanding Feedback (carry to next session)
- Bryan: "I have a lot of feedback still but you're struggling with the visuals. I might give up."
- Knob knurling realism still needs work
- MOOD logo area needs more impact
- Clock knob circumference values not yet done
- Per-channel Brothers AM color coding needs in-app verification
- General: visual fidelity gap vs. real CB pedals — consider different approach next session

---

## Session 10 — Hardware Planning: 1590B Drilling & Wire Reference

**Date:** 02.20.2026
**Time spent:** ~20m

### What We Built
- Answered drilling and wiring questions for the MIDI-to-TRS converter box (Hammond 1590B)
- Confirmed visual reference section in `midi-controller-complete-guide-v2.md` covering:
  - Drilling template (top-face ASCII layout with hole sizes)
  - Hole size table: 5/8" DIN, 3/8" x4 TRS, switch slots x4
  - Wire cut sheet: 16 wires with length, color, and From→To for each
  - Color legend: Black=ground, Red=signal, White=Ring, Yellow=Tip
  - Solder point map: DIN jack, SPDT switch, and TRS jack labeled diagrams

### What Shipped
- GitHub issue #15 created, time logged (20m), closed → Notion sync triggered

### Decisions Made
- Wire color convention: Black/Red/White/Yellow (ground, signal, ring, tip) for the converter build

---

---

## Session 11 — Bat Switch Overhaul + Toggle Row Polish

**Date:** 02.20.2026
**Time spent:** ~2h

### What We Built
- Two complete bat switch visual variants for side-by-side comparison:
  - **Option B** (`ToggleSwitch3Way`): thin chrome stem + dome cap using a custom `BatStem: Shape` with `Animatable` conformance for smooth spring animation
  - **Option A** (`ToggleSwitch3WayRotating`): single tapered rotating paddle using `CGAffineTransform` inside a custom `RotatingPaddle: Shape` — no `rotationEffect` modifier needed
- Paddle tilt increased to ±40° for a more pronounced lean
- Option labels moved below bat switch housing; parameter name labels removed
- Dark rectangular housing boxes stripped from bat switches — paddles now float directly on pedal face with just the hex nut
- `HiddenSettingsPanel` background rectangle removed
- MOOD MK2 micro-looper options renamed: ENV / Tape / Stretch
- Brothers AM treble boost ◑ → ○ (outline sun)

### What Shipped
- `ToggleSwitch3WayRotating.swift` (new file, Option A — now active in app)
- `ToggleSwitch3Way.swift` (reworked to Option B — kept as alternate)
- All pedal definition + enclosure visual changes committed and pushed

### Bugs Fixed
- **Xcode "Cannot find ToggleSwitch3WayRotating in scope"** — root cause: `MIDIControl.xcodeproj` is gitignored, so new files added outside Xcode are not auto-discovered. Fix: run `xcodegen generate` after any file add/remove. Always open `.xcodeproj`, never `Package.swift`, to run the GUI app.

### Decisions Made
- Option A (rotating paddle) selected as preferred bat switch visual
- Option B kept in codebase as `ToggleSwitch3Way` for potential future use
- Housing box removed from toggles: real pedal aesthetic — levers mount through holes in the face, no external box
- Always use `MIDIControl.xcodeproj` to run app; `Package.swift` builds CLI-only target

---

## Session 12 — Hardware Planning: Option B Enclosure Layout + MIDI Thru

**Date:** 02.20.2026
**Time spent:** ~45m

### What We Built
- Worked through 4 enclosure layout options for the 1590B MIDI-to-TRS converter box
- Selected **Option B**: TRS jacks on long side, both DIN connectors on short side A, SPDT switches on top face
- Confirmed **MIDI Thru is passive** (no power required) — just taps DIN IN pins 5 and 2 to a second DIN connector, 2 extra wires
- Updated `midi-controller-complete-guide-v2.md` with:
  - New 3-face enclosure layout diagram
  - 3 separate drilling templates (one per face) with exact hole positions and dimensions
  - Updated Hole Sizes table with Face column and DIN THRU row
  - Wire cut sheet expanded to 18 wires (added wires 17–18 for MIDI Thru)
  - Build Step 1 updated to reference all 3 faces
- Installed Sublime Text (moved from Downloads → /Applications) and set as default for .md files

### What Shipped
- Updated `midi-controller-complete-guide-v2.md` committed (was already in HEAD)
- GitHub issue #17 created, time logged (45m), closed → Notion sync triggered

### Decisions Made
- Option B layout: cables exit the long side (best for pedalboard routing), MIDI cables at short end
- MIDI Thru is passive — confirmed no power needed, 2 wires tap from DIN IN
- SPDT switches stay on top face for set-and-forget Ring/Tip config (visible from above)
- Short Side B left blank — reserved for power jack if ever added later
- Switch slots aligned at same x-positions as TRS jacks (16mm, 38mm, 60mm, 82mm) for visual correspondence

---

*To add a new session: copy the session template below and fill in details.*

```markdown
## Session N — [Title]

**Date:** MM.DD.YYYY
**Time spent:** Xh Xm Xs

### What We Built
-

### What Shipped
-

### Bugs Fixed
-

### Decisions Made
-
```

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

## Backlog / Ideas

*Things mentioned but not built yet:*

- [ ] iOS companion app
- [ ] User-defined pedal definitions (JSON import)
- [ ] MIDI learn mode
- [ ] Sequence/automation recording
- [ ] App icon
- [ ] Keyboard shortcuts for common actions

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

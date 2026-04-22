# Visual Design Reference — Chase Bliss Pedals

Read this file when doing visual/UI work on the pedal interface.

## Toggle Bat Switches
- Physical CB toggle switches: bat pivots from CENTER of housing
- Correct top-down rendering: portrait oval (tall + narrow) that SHIFTS HORIZONTALLY
- DO NOT use `rotationEffect` on the bat — it looks wrong. Use xShift + no rotation.
- Left = oval shifts left, Center = circle, Right = oval shifts right
- ovalW ≈ 0.58× batDiameter, ovalH ≈ 1.55× batDiameter when tilted

## Knob Visual Layers (top to bottom in ZStack)
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

## Chase Bliss Logos
- CB logo between footswitches: thin ring + "CB" text, NOT any SF Symbol person/figure
- AM badge (Brothers): 12-spike star OUTLINE (stroke, not fill) + filled gold circle center + "AM" text
- MOOD brand: large bold italic "MOOD" with sunset gradient, "MKii" bottom-right corner

## App Icon
`Views/AppIconView.swift` — pure SwiftUI Canvas drawing of the 1024×1024 app icon.
Design: dark maroon pedal enclosure + 1/4" TS cables plugged into both sides + central amber-arc knob.

**To export PNG for asset catalog:**
1. Open `AppIconView.swift` in Xcode, open Preview canvas
2. Select the `"1024×1024 full"` preview
3. Right-click → "Save Image…", save as `AppIcon-1024.png`
4. Move to: `Sources/MIDIControl/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`
5. Run `xcodegen generate`

**Asset catalog:** `Sources/MIDIControl/Assets.xcassets/AppIcon.appiconset/`
**project.yml setting:** `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` (iOS target only)

## V2 Image-Based UI (tabled — assets ready)
Generated PNG assets are in `~/Documents/Claude/Midi Control/Pedal UI Images/`:
- `Brothers AM Base enclosure.png`, `MoodMK2 base enclosure.png` — full pedal photos (NOT usable as interactive backgrounds)
- `left/center/right bat switch.png` — 3-state image swap for toggles
- `Plum knob pink/white/yellow indicator.png` — indicator at 12 o'clock; rotate whole image for knob turn

**Recommended approach (Option A):** Image knobs + bat switch images, drawn enclosure stays. Work on branch `v2-image-based`.
Visual mock at `~/Documents/Claude/Midi Control/v2-image-mock.html`.

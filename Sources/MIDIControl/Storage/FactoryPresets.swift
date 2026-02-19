import Foundation

/// Factory preset data sourced from the Chase Bliss Brothers AM manual.
/// These are the named presets that ship on the physical pedal.
///
/// CC values are per the official MIDI manual. Note: some dip switch CCs
/// in the current app may have incorrect labels — the CC numbers here are correct
/// per the MIDI manual (e.g., CC 71 = Hi Gain 1, not "Order").
enum FactoryPresets {

    /// Seed factory presets for all pedals if they haven't been created yet.
    /// Uses UserDefaults to avoid re-seeding on every launch.
    /// v4: adds dedup cleanup before saving so repeated version bumps don't stack duplicates.
    static func seedIfNeeded(storage: PresetStorage) {
        let key = "factoryPresetsSeeded_v4"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        // Remove any duplicates (by name) accumulated from previous seed versions
        cleanupDuplicates(storage: storage)

        // Save each preset only if a preset with that name doesn't already exist
        for preset in brothersAMPresets + moodMKIIPresets {
            let existing = storage.loadPresets(for: preset.pedalId)
            if !existing.contains(where: { $0.name == preset.name }) {
                storage.save(preset)
            }
        }

        UserDefaults.standard.set(true, forKey: key)
    }

    /// Removes duplicate presets (keeping the first occurrence by name) for all pedals.
    private static func cleanupDuplicates(storage: PresetStorage) {
        for pedalId in ["brothers-am", "mood-mkii"] {
            let presets = storage.loadPresets(for: pedalId)
            var seen: Set<String> = []
            for preset in presets {
                if seen.contains(preset.name) {
                    storage.delete(preset)
                } else {
                    seen.insert(preset.name)
                }
            }
        }
    }

    // MARK: - Brothers AM Factory Presets

    /// All Brothers AM presets: 4 factory presets + 7 manual idea presets.
    static let brothersAMPresets: [Preset] = [
        // Factory presets (Default Bank + Alt Bank)
        theAnalogMan,
        sunnySkies,
        twoInOne,
        badBros,
        // Two-Channel Ideas (manual pages 18–20)
        cleanChannelDirtyChannel,
        ampPusher,
        // Stacking Ideas (manual pages 21–23)
        overloader,
        expander,
        combo,
        // Treble Booster Settings (manual pages 24–27)
        cuttingCleans,
        fullStack,
        liftedDistortion,
    ]

    /// THE ANALOG MAN
    /// Mike Piera's preferred King of Tone settings. Solid starter for experiencing
    /// the pedal as intended. Kick Channel 2 on for an extra lift. Hi Gain 1 active.
    private static let theAnalogMan = Preset(
        name: "The Analog Man",
        pedalId: "brothers-am",
        midiChannel: 2,
        parameters: [
            14: 55,   // Gain 2 — moderate
            15: 90,   // Volume 2 — strong output
            16: 40,   // Gain 1 — moderate, KoT-style
            17: 64,   // Tone 2 — center
            18: 80,   // Volume 1 — balanced
            19: 64,   // Tone 1 — center
            21: 2,    // Gain 2 Type — OD (King of Tone)
            22: 2,    // Treble Boost — Off
            23: 2,    // Gain 1 Type — OD (King of Tone)
            27: 0,    // Presence 2 — down (recommended default)
            29: 0,    // Presence 1 — down (recommended default)
            71: 127,  // Hi Gain 1 ON (CC 71 per MIDI manual — app may label as 'Order')
        ],
        notes: "Mike Piera's preferred KoT settings. Default bank Preset 1. Both channels in OD mode. Channel 2 adds a lift when engaged. Hi Gain 1 active. Approximate — tweak to taste.",
        tags: ["factory", "overdrive", "KoT"]
    )

    /// SUNNY SKIES
    /// Mixture of everything Brothers AM offers. Treble boost into distortion into
    /// overdrive for a bright, focused, charged sound.
    private static let sunnySkies = Preset(
        name: "Sunny Skies",
        pedalId: "brothers-am",
        midiChannel: 2,
        parameters: [
            14: 55,   // Gain 2
            15: 85,   // Volume 2
            16: 65,   // Gain 1
            17: 70,   // Tone 2 — slightly bright
            18: 78,   // Volume 1
            19: 78,   // Tone 1 — bright
            21: 3,    // Gain 2 Type — Dist
            22: 0,    // Treble Boost — Full Sun
            23: 0,    // Gain 1 Type — Dist
            27: 18,   // Presence 2 — slight boost
            29: 18,   // Presence 1 — slight boost
        ],
        notes: "Default bank Preset 2. Full Sun treble boost into distortion × 2. Bright, focused, charged. Approximate — tweak to taste.",
        tags: ["factory", "distortion", "bright"]
    )

    /// 2-IN-1
    /// Channel 2 is always-on overdrive foundation; Channel 1 boosts it into overdrive.
    /// Keep Channel 1 off by default, engage it when you need more bite.
    private static let twoInOne = Preset(
        name: "2-In-1",
        pedalId: "brothers-am",
        midiChannel: 2,
        parameters: [
            14: 50,   // Gain 2 — moderate OD foundation
            15: 82,   // Volume 2
            16: 88,   // Gain 1 — high boost level
            17: 64,   // Tone 2
            18: 90,   // Volume 1 — loud when engaged
            19: 64,   // Tone 1
            21: 2,    // Gain 2 Type — OD (always-on foundation)
            22: 2,    // Treble Boost — Off
            23: 3,    // Gain 1 Type — Boost (boosts Channel 2)
            27: 0,    // Presence 2
            29: 0,    // Presence 1
        ],
        notes: "Alt bank Preset 3. Channel 2 = always-on OD; Channel 1 = boost to push it further. Leave Ch1 bypassed, engage for more bite. Approximate — tweak to taste.",
        tags: ["factory", "boost", "overdrive", "alt-bank"]
    )

    /// BAD BROS
    /// As big and brash as Brothers AM can get. Maximum distortion stacking with
    /// Hi Gain on both channels. Overflowing.
    private static let badBros = Preset(
        name: "Bad Bros",
        pedalId: "brothers-am",
        midiChannel: 2,
        parameters: [
            14: 108,  // Gain 2 — cranked
            15: 88,   // Volume 2
            16: 108,  // Gain 1 — cranked
            17: 64,   // Tone 2
            18: 80,   // Volume 1
            19: 64,   // Tone 1
            21: 3,    // Gain 2 Type — Dist
            22: 2,    // Treble Boost — Off
            23: 0,    // Gain 1 Type — Dist
            27: 0,    // Presence 2
            29: 0,    // Presence 1
            71: 127,  // Hi Gain 1 ON
            72: 127,  // Hi Gain 2 ON
        ],
        notes: "Alt bank Preset 4. Maximum everything. Hi Gain on both channels + both Dist modes. Overflowing distortion. Approximate — tweak to taste.",
        tags: ["factory", "distortion", "heavy", "alt-bank"]
    )

    // MARK: - Two-Channel Ideas (manual pages 18–20)

    /// CLEAN CHANNEL / DIRTY CHANNEL
    /// Channel 2 is a always-on clean boost; Channel 1 is the dirty channel you
    /// kick on for solos or heavy sections. Volume 2 set conservatively so the
    /// clean boost doesn't overwhelm. Channel 1 in OD mode for natural breakup.
    private static let cleanChannelDirtyChannel = Preset(
        name: "Clean / Dirty",
        pedalId: "brothers-am",
        midiChannel: 2,
        parameters: [
            14: 10,   // Gain 2 — very low, nearly clean
            15: 75,   // Volume 2 — unity or slight boost
            16: 60,   // Gain 1 — medium-high OD
            17: 64,   // Tone 2 — neutral
            18: 95,   // Volume 1 — louder for solo lift
            19: 64,   // Tone 1 — neutral
            21: 0,    // Gain 2 Type — Boost (cleanest option)
            22: 2,    // Treble Boost — Off
            23: 2,    // Gain 1 Type — OD
            27: 0,    // Presence 2
            29: 0,    // Presence 1
            77: 127,  // Master ON — Volume 2 controls overall level, no jumps
        ],
        notes: "Two-channel idea from manual. Channel 2 = always-on clean boost foundation. Channel 1 = dirty channel for solos. Master dip keeps volume consistent between modes. Approximate — tweak to taste.",
        tags: ["two-channel", "clean", "overdrive", "manual"]
    )

    /// AMP PUSHER
    /// Both channels push your amp rather than dominate the tone themselves.
    /// Low gain, volume cranked — adds clarity, sustain, and punch without
    /// dramatically changing the amp's character. Stack both for more push.
    private static let ampPusher = Preset(
        name: "Amp Pusher",
        pedalId: "brothers-am",
        midiChannel: 2,
        parameters: [
            14: 15,   // Gain 2 — very low
            15: 110,  // Volume 2 — loud, pushing the amp
            16: 15,   // Gain 1 — very low
            17: 64,   // Tone 2 — neutral
            18: 110,  // Volume 1 — loud
            19: 64,   // Tone 1 — neutral
            21: 0,    // Gain 2 Type — Boost
            22: 2,    // Treble Boost — Off
            23: 3,    // Gain 1 Type — Boost
            27: 0,    // Presence 2
            29: 0,    // Presence 1
        ],
        notes: "Two-channel idea from manual. Low gain, high volume — pushes the amp input for more sustain and punch without coloring the tone heavily. Stack both channels for more drive. Approximate — tweak to taste.",
        tags: ["two-channel", "boost", "amp-drive", "manual"]
    )

    // MARK: - Stacking Ideas (manual pages 21–23)

    /// OVERLOADER
    /// Channel 1 (Dist) runs into Channel 2 (OD). The distortion character of
    /// Ch1 gets fed into the soft-clipping of Ch2 for a thick, harmonically
    /// complex stacked sound. Both channels active simultaneously.
    private static let overloader = Preset(
        name: "Overloader",
        pedalId: "brothers-am",
        midiChannel: 2,
        parameters: [
            14: 50,   // Gain 2 — moderate OD
            15: 82,   // Volume 2
            16: 70,   // Gain 1 — moderate Dist
            17: 60,   // Tone 2 — slightly dark to tame stacking
            18: 85,   // Volume 1
            19: 60,   // Tone 1 — slightly dark
            21: 2,    // Gain 2 Type — OD (receives Dist output)
            22: 2,    // Treble Boost — Off
            23: 0,    // Gain 1 Type — Dist (feeds into OD)
            27: 0,    // Presence 2
            29: 0,    // Presence 1
        ],
        notes: "Stacking idea from manual. Dist (Ch1) into OD (Ch2) — layered saturation. Thick, complex harmonic stacking. Darken tones slightly to avoid harshness at high gain. Approximate — tweak to taste.",
        tags: ["stacking", "distortion", "overdrive", "manual"]
    )

    /// EXPANDER
    /// Channel 2 is always-on OD; Channel 1 is a boost that expands the
    /// drive and output when engaged. Subtle stacking — OD stays controlled,
    /// Ch1 boost adds volume and push without radically changing the tone.
    private static let expander = Preset(
        name: "Expander",
        pedalId: "brothers-am",
        midiChannel: 2,
        parameters: [
            14: 45,   // Gain 2 — moderate OD foundation
            15: 80,   // Volume 2
            16: 20,   // Gain 1 — low-gain boost
            17: 64,   // Tone 2 — neutral
            18: 95,   // Volume 1 — louder boost
            19: 68,   // Tone 1 — slightly bright
            21: 2,    // Gain 2 Type — OD (always-on foundation)
            22: 2,    // Treble Boost — Off
            23: 3,    // Gain 1 Type — Boost
            27: 0,    // Presence 2
            29: 0,    // Presence 1
        ],
        notes: "Stacking idea from manual. Always-on OD (Ch2) expanded by a clean boost (Ch1). Kick Ch1 in for more output and push. Stays musical and controlled. Approximate — tweak to taste.",
        tags: ["stacking", "boost", "overdrive", "manual"]
    )

    /// COMBO
    /// Both channels in OD mode, each voiced slightly differently — one darker,
    /// one brighter. Together they create a fuller combined sound than either
    /// alone, like running through two separate amp channels simultaneously.
    private static let combo = Preset(
        name: "Combo",
        pedalId: "brothers-am",
        midiChannel: 2,
        parameters: [
            14: 55,   // Gain 2 — moderate OD
            15: 78,   // Volume 2
            16: 50,   // Gain 1 — slightly lower OD
            17: 72,   // Tone 2 — brighter
            18: 82,   // Volume 1
            19: 55,   // Tone 1 — darker
            21: 2,    // Gain 2 Type — OD
            22: 2,    // Treble Boost — Off
            23: 2,    // Gain 1 Type — OD
            27: 8,    // Presence 2 — slight boost for brightness
            29: 0,    // Presence 1
        ],
        notes: "Stacking idea from manual. Two OD channels voiced differently — one bright, one dark. Combined for a fuller, richer overdrive tone. Approximate — tweak to taste.",
        tags: ["stacking", "overdrive", "manual"]
    )

    // MARK: - Treble Booster Settings (manual pages 24–27)

    /// CUTTING CLEANS
    /// Treble boost (Half Sun) with both channels in low-gain Boost mode.
    /// Adds presence and cut without adding distortion — works well with
    /// single-coil pickups or when you need to slice through a dense mix.
    private static let cuttingCleans = Preset(
        name: "Cutting Cleans",
        pedalId: "brothers-am",
        midiChannel: 2,
        parameters: [
            14: 8,    // Gain 2 — very low, nearly clean
            15: 85,   // Volume 2
            16: 8,    // Gain 1 — very low
            17: 72,   // Tone 2 — brighter
            18: 85,   // Volume 1
            19: 72,   // Tone 1 — brighter
            21: 0,    // Gain 2 Type — Boost
            22: 3,    // Treble Boost — Half Sun
            23: 3,    // Gain 1 Type — Boost
            27: 12,   // Presence 2 — slight
            29: 12,   // Presence 1 — slight
        ],
        notes: "Treble booster idea from manual. Half Sun treble boost + low-gain boosts for presence and cut. Stays clean. Good for single-coils in dense mixes. Approximate — tweak to taste.",
        tags: ["treble-boost", "clean", "boost", "manual"]
    )

    /// FULL STACK
    /// Full Sun treble boost driving both channels in Dist mode with Hi Gain
    /// on both. Maximum brightness and saturation — bright, cutting, heavily
    /// saturated lead tone.
    private static let fullStack = Preset(
        name: "Full Stack",
        pedalId: "brothers-am",
        midiChannel: 2,
        parameters: [
            14: 85,   // Gain 2 — high Dist
            15: 82,   // Volume 2
            16: 85,   // Gain 1 — high Dist
            17: 72,   // Tone 2 — bright
            18: 80,   // Volume 1
            19: 72,   // Tone 1 — bright
            21: 3,    // Gain 2 Type — Dist
            22: 0,    // Treble Boost — Full Sun
            23: 0,    // Gain 1 Type — Dist
            27: 20,   // Presence 2 — notable boost
            29: 20,   // Presence 1 — notable boost
            71: 127,  // Hi Gain 1 ON
            72: 127,  // Hi Gain 2 ON
        ],
        notes: "Treble booster idea from manual. Full Sun into Hi Gain Dist × 2. Maximum brightness and saturation. Cuts through anything — use carefully. Approximate — tweak to taste.",
        tags: ["treble-boost", "distortion", "heavy", "bright", "manual"]
    )

    /// LIFTED DISTORTION
    /// Half Sun treble boost into Channel 2 Dist only, with Channel 1 as a
    /// clean boost. Lifts a tight, focused distortion tone with added presence
    /// and some extra push from Ch1 when needed.
    private static let liftedDistortion = Preset(
        name: "Lifted Distortion",
        pedalId: "brothers-am",
        midiChannel: 2,
        parameters: [
            14: 75,   // Gain 2 — solid Dist
            15: 85,   // Volume 2
            16: 12,   // Gain 1 — low, clean boost
            17: 68,   // Tone 2 — slightly bright
            18: 92,   // Volume 1 — louder boost level
            19: 64,   // Tone 1 — neutral
            21: 3,    // Gain 2 Type — Dist
            22: 3,    // Treble Boost — Half Sun
            23: 3,    // Gain 1 Type — Boost (lift option)
            27: 10,   // Presence 2 — subtle
            29: 0,    // Presence 1
        ],
        notes: "Treble booster idea from manual. Half Sun + Dist (Ch2). Ch1 acts as an optional boost/lift when engaged. Focused and punchy. Approximate — tweak to taste.",
        tags: ["treble-boost", "distortion", "boost", "manual"]
    )

    // MARK: - MOOD MKII Presets

    /// All MOOD MKII presets, sourced from manual ideas and mode demonstrations.
    static let moodMKIIPresets: [Preset] = [
        moodAmbientStarter,
        moodReverbFreeze,
        moodSelfStretchLoop,
        moodLoFiTapeEcho,
        moodSlipHarmonizer,
        moodTextureFactory,
    ]

    /// AMBIENT STARTER
    /// The "good default" from the Getting Started page of the manual (pg. 6–7).
    /// Reverb mode, Clock slightly lower for texture. A reliable launching point
    /// for any ambient or textural exploration.
    private static let moodAmbientStarter = Preset(
        name: "Ambient Starter",
        pedalId: "mood-mkii",
        midiChannel: 2,
        parameters: [
            14: 45,   // Time — moderate reverb size/decay
            15: 80,   // Mix — mostly wet
            16: 64,   // Length — center
            17: 20,   // Modify (Wet) — low = multi-tap territory, smear up from here
            18: 45,   // Clock — slightly lower for texture and lo-fi color
            19: 64,   // Modify (Loop) — center
            21: 0,    // Wet Channel — Reverb
            22: 64,   // Routing — Parallel (input + loop feed wet)
            23: 64,   // Micro-Looper — Tape
        ],
        notes: "Based on the Getting Started page. Reverb with slightly lowered Clock for texture. Turn down Clock further for more grit. Roll up Modify to go from multi-tap clusters to washed-out reverb. Approximate — tweak to taste.",
        tags: ["reverb", "ambient", "starter", "manual"]
    )

    /// REVERB FREEZE PAD
    /// Reverb mode set for a percussive frozen pattern. Modify down = multi-tap
    /// pattern. Engage Freeze to hold it. Once frozen, slowly increase Modify
    /// to smear the pattern into an ambient wash — you can't go back once smeared.
    private static let moodReverbFreeze = Preset(
        name: "Reverb Freeze Pad",
        pedalId: "mood-mkii",
        midiChannel: 2,
        parameters: [
            14: 70,   // Time — longer decay / larger room
            15: 90,   // Mix — very wet
            16: 64,   // Length
            17: 10,   // Modify (Wet) — low = distinct multi-tap pattern when frozen
            18: 55,   // Clock — slightly reduced for warmth
            19: 64,   // Modify (Loop)
            21: 0,    // Wet Channel — Reverb
            22: 0,    // Routing — Input Only
            23: 64,   // Micro-Looper — Tape
        ],
        notes: "Freeze Ideas (manual pg. 22). Reverb with Modify down = frozen percussive pattern. Use Freeze button to lock it. Slowly raise Modify after freezing to smear into ambient pad — irreversible once smeared. Approximate — tweak to taste.",
        tags: ["reverb", "freeze", "ambient", "manual"]
    )

    /// SELF-STRETCH LOOP
    /// Delay mode with max feedback — behaves like a looper. Once audio is
    /// looping, slowly rotate Time clockwise: the delay 'stretches' the loop.
    /// A recorded trick from the manual's Loop Tricks section.
    private static let moodSelfStretchLoop = Preset(
        name: "Self-Stretch Loop",
        pedalId: "mood-mkii",
        midiChannel: 2,
        parameters: [
            14: 50,   // Time — moderate delay, then sweep CW after loop established
            15: 85,   // Mix — mostly wet
            16: 64,   // Length
            17: 127,  // Modify (Wet) — max feedback: repeats pile up like a looper
            18: 64,   // Clock — clean, hi-fi
            19: 64,   // Modify (Loop)
            21: 64,   // Wet Channel — Delay
            22: 127,  // Routing — W>L: looper channel feeds through wet delay
            23: 64,   // Micro-Looper — Tape
        ],
        notes: "Loop Tricks (manual pg. 24). Max Delay feedback = stable looping. Slowly rotate Time CW while looping to create a self-stretching effect recorded into the loop. Approximate — tweak to taste.",
        tags: ["delay", "loop", "stretch", "manual"]
    )

    /// LO-FI TAPE ECHO
    /// The Balance Beam technique from the Tape mode section (manual pg. 33).
    /// Clock lowered for grit and character. Modify (Loop) raised to speed the
    /// loop back up to match played tempo — same speed, but dirtier and more
    /// characterful. Classic lo-fi texture.
    private static let moodLoFiTapeEcho = Preset(
        name: "Lo-Fi Tape Echo",
        pedalId: "mood-mkii",
        midiChannel: 2,
        parameters: [
            14: 55,   // Time — moderate reverb color
            15: 70,   // Mix — balanced
            16: 64,   // Length — normal loop size
            17: 30,   // Modify (Wet) — slight smear
            18: 22,   // Clock — low = lo-fi, gritty, longer loops
            19: 100,  // Modify (Loop) — speed up loop to compensate for lower Clock
            21: 0,    // Wet Channel — Reverb (adds ambient layer)
            22: 64,   // Routing — Parallel
            23: 64,   // Micro-Looper — Tape
        ],
        notes: "Balance Beam technique (manual pg. 33). Lower Clock for grit and character. Raise Modify (Loop) to play the loop back at roughly normal speed despite the lo-fi Clock. Same tempo, more texture. Approximate — tweak to taste.",
        tags: ["looper", "lo-fi", "tape", "manual"]
    )

    /// SLIP HARMONIZER
    /// Slip mode functions as a continuous pitch-shifter / auto-harmonizer.
    /// Lower Time = pitch-shifter feel with instant response. Modify slightly
    /// above center = gentle pitch-up in semitone steps. Great for subtle
    /// harmonies following your playing.
    private static let moodSlipHarmonizer = Preset(
        name: "Slip Harmonizer",
        pedalId: "mood-mkii",
        midiChannel: 2,
        parameters: [
            14: 25,   // Time — low = pitch-shifter feel, instant response
            15: 55,   // Mix — balanced, don't lose the dry signal
            16: 64,   // Length
            17: 70,   // Modify (Wet) — slightly above center = gentle pitch-up
            18: 64,   // Clock — hi-fi for clean pitch shifting
            19: 64,   // Modify (Loop)
            21: 127,  // Wet Channel — Slip
            22: 0,    // Routing — Input Only
            23: 64,   // Micro-Looper — Tape
        ],
        notes: "Slip mode as a pitch-harmonizer (manual pg. 26). Low Time = immediate pitch-shifting. Modify above center = harmonies following your playing in semitone steps. Move Modify to transpose. Approximate — tweak to taste.",
        tags: ["slip", "pitch", "harmonizer", "manual"]
    )

    /// TEXTURE FACTORY
    /// Both channels working together: micro-loop fed through Reverb for
    /// maximum ambience. Low Clock for grit. The looper continuously captures
    /// the reverb trails as they happen — each loop is unique.
    private static let moodTextureFactory = Preset(
        name: "Texture Factory",
        pedalId: "mood-mkii",
        midiChannel: 2,
        parameters: [
            14: 80,   // Time — long reverb trails
            15: 95,   // Mix — very wet
            16: 64,   // Length
            17: 60,   // Modify (Wet) — slight smear
            18: 35,   // Clock — lo-fi texture
            19: 64,   // Modify (Loop) — center
            21: 0,    // Wet Channel — Reverb
            22: 127,  // Routing — W>L: looper feeds through reverb
            23: 0,    // Micro-Looper — Stretch
        ],
        notes: "Both channels interacting (manual pg. 28–29). Micro-loop routed through Reverb. Low Clock = gritty loops. Looper captures reverb trails in always-listening state. Stretch mode on looper for time-stretching exploration. Approximate — tweak to taste.",
        tags: ["ambient", "texture", "reverb", "loop", "manual"]
    )
}

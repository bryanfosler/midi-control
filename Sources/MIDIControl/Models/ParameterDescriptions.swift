import Foundation

/// Human-readable tooltip descriptions for all parameters on both pedals.
/// Sourced from Chase Bliss Brothers AM and MOOD MKII manuals.
///
/// Lookup priority:
///   1. "\(pedalId)/\(paramId)"  — pedal-specific by param ID
///   2. "\(pedalId)/cc\(cc)"     — pedal-specific by CC number (used for dip switches
///                                  where app labels may differ from manual)
///   3. "\(paramId)"             — global fallback for shared params
enum ParameterDescriptions {

    static func description(for paramId: String, cc: Int, pedalId: String) -> String {
        if let d = lookup["\(pedalId)/\(paramId)"] { return d }
        if let d = lookup["\(pedalId)/cc\(cc)"] { return d }
        return lookup[paramId] ?? ""
    }

    // MARK: - Lookup Table

    private static let lookup: [String: String] = [

        // ─── BROTHERS AM ─────────────────────────────────────────────────────

        // Knobs
        "gain1": "Controls the gain (saturation) of Channel 1. Gradually increasing this adds drive and affects output level. At higher settings, Channel 1 pushes Channel 2 deeper into saturation when both channels are on. Also known as the left yellow knob on the physical pedal.",
        "gain2": "Controls the gain (saturation) of Channel 2. When both channels are active, Channel 1 can push this further. Final output level is governed by Volume 2. Right yellow knob on the physical pedal.",
        "volume1": "Output level for Channel 1 alone. When Channel 2 is bypassed, the pedal's output jumps to this level — watch for sudden volume changes. Enable the MASTER dip switch to use Volume 2 as a global master so level stays consistent.",
        "volume2": "Output level for Channel 2. When both channels are active, sets the final combined output volume. With the MASTER dip switch on, this knob controls overall level at all times, even when Channel 2 is bypassed — prevents volume spikes between modes.",
        "tone1": "Voicing control for Channel 1. Turning right brightens the sound; turning left darkens it. When the PRES LINK 1 dip switch is active, this knob simultaneously adjusts Channel 1's Presence setting for even more tonal range.",
        "tone2": "Voicing control for Channel 2. Turning right brightens; turning left darkens. When the PRES LINK 2 dip switch is active, this knob also controls Channel 2's Presence setting.",
        "presence1": "Boosts high frequencies for Channel 1 — adds air, brilliance, and upper-end sparkle.\n\nPhysical pedal access: Hold the Channel 1 footswitch for ~3 seconds, then adjust the Tone 1 knob while holding.\n\nRecommended starting point: all the way down (zero). Add slowly. Adjustable here directly without the hold.",
        "presence2": "Boosts high frequencies for Channel 2 — adds air, brilliance, and upper-end sparkle.\n\nPhysical pedal access: Hold the Channel 2 footswitch for ~3 seconds, then adjust the Tone 2 knob while holding.\n\nRecommended starting point: all the way down (zero). Adjustable here directly without the hold.",

        // Toggles
        "gain1type": "Selects the gain circuit style for Channel 1:\n\n• DIST — Hard-clipping distortion. More compression and saturation than OD, retains clarity. Good for full-on driven tones.\n• OD — Soft-clipping overdrive (King of Tone circuit). Natural, open character that preserves your instrument's voice.\n• BOOST — Clean boost capable of low-gain overdrive. Loudest output of the three modes. Great for pushing Channel 2 harder or stacking into an amplifier.",
        "gain2type": "Selects the gain circuit style for Channel 2:\n\n• BOOST — Clean boost, loudest output. Transparent character.\n• OD — Soft-clipping King of Tone overdrive. Natural and open.\n• DIST — Hard-clipping distortion. Compressed and saturated.",
        "trebleboost": "Engages a Rangemaster-style treble booster at the very front of the signal chain (before both channels):\n\n• OFF — No boost, signal passes clean.\n• HALF SUN — Classic Rangemaster sound with heavy emphasis on upper mids. Focused and cutting.\n• FULL SUN — More cutting and bright than Half Sun. Excellent for standing out in a dense mix or adding jangle to humbuckers.",

        // Footswitches
        "ch1bypass": "Toggles Channel 1 on/off. LED glows when active (turns RED when HI GAIN 1 dip is enabled).\n\nOn physical pedal: Hold for ~3 seconds to access the PRESENCE control — Tone knob adjusts Presence while held. Direct Presence control is available above.",
        "ch2bypass": "Toggles Channel 2 on/off. LED glows when active (turns RED when HI GAIN 2 dip is enabled).\n\nOn physical pedal: Hold for ~3 seconds to access the PRESENCE control — Tone knob adjusts Presence while held. Direct Presence control is available above.",
        "presetsave": "Saves current settings as a preset to the pedal's internal hardware memory (CC 111). On physical pedal: hold both footswitches and send a Program Change message. Slots 1–122 available. Sending PC 0 returns to Live mode.",

        // Brothers AM Expression
        "brothers-am/expression": "Controls parameters via expression pedal or CV input (0–5V, do not exceed). Configure which knobs respond using the Left Bank dip switches, and set sweep direction/range using the Sweep and Polarity dips.\n\nCV input uses a TRS-to-TS cable (floating ring). Expression pedal uses a standard TRS cable.",

        // Brothers AM Dip Switches — Left Bank (CC 61–68) — CONTROL
        // These select which knobs respond to expression / CV / MIDI ramping
        "brothers-am/dip_vol1": "VOL 1 — Volume 1 expression/ramping participation.\n\nWhen ON, the Volume 1 knob responds to an expression pedal, CV input, or ramping function. Set sweep range and direction using the Sweep and Polarity dips in this same bank.",
        "brothers-am/dip_vol2": "VOL 2 — Volume 2 expression/ramping participation.\n\nWhen ON, Volume 2 responds to expression/CV/ramp control. Useful for automated volume swells or expression-controlled output level.",
        "brothers-am/dip_gain1": "GAIN 1 — Gain 1 expression/ramping participation.\n\nWhen ON, the Gain 1 knob responds to expression/CV/ramp control. Great for real-time dynamic gain sweeps — sweep from clean to driven with a foot pedal.",
        "brothers-am/dip_gain2": "GAIN 2 — Gain 2 expression/ramping participation.\n\nWhen ON, Gain 2 responds to expression/CV/ramp control.",
        "brothers-am/dip_tone1": "TONE 1 — Tone 1 expression/ramping participation.\n\nWhen ON, Tone 1 responds to expression/CV/ramp control. Enables real-time tonal sweeps from dark to bright.",
        "brothers-am/dip_tone2": "TONE 2 — Tone 2 expression/ramping participation.\n\nWhen ON, Tone 2 responds to expression/CV/ramp control.",
        "brothers-am/dip_sweep": "SWEEP — Sets the sweep range for all engaged expression/CV knobs:\n\n• OFF (Bottom): Sweeps from minimum up to the current knob position.\n• ON (Top): Sweeps from the current knob position up to maximum.\n\nGlobal setting — applies to all knobs enabled in this bank.",
        "brothers-am/dip_polarity": "POLARITY — Sets the direction of expression/CV control:\n\n• OFF (Forward): Heel position = minimum, toe = maximum.\n• ON (Reverse): Heel position = maximum, toe = minimum.\n\nFlip this if your expression pedal feels backwards.",

        // Brothers AM Dip Switches — Right Bank (CC 71–78) — CUSTOMIZE
        // These engage alternate behaviors and features
        "brothers-am/dip_hi_gain_1": "HI GAIN 1 — Increases Channel 1's gain by approximately 25% across all modes (Boost, OD, Dist). The circuit character stays the same — you're just driving it harder.\n\nThe Channel 1 bypass LED turns RED when this is active (normally green).",
        "brothers-am/dip_hi_gain_2": "HI GAIN 2 — Increases Channel 2's gain by approximately 25% across all modes. Same circuit character, more output drive.\n\nThe Channel 2 bypass LED turns RED when active.",
        "brothers-am/dip_motobyp_1": "MOTOBYP 1 (Momentary to Bypass) — Converts the Channel 1 footswitch to momentary mode. Channel 1 only engages while the footswitch is physically held down.\n\nUseful for brief, controlled moments of boost or drive without latching it on.",
        "brothers-am/dip_motobyp_2": "MOTOBYP 2 (Momentary to Bypass) — Converts the Channel 2 footswitch to momentary mode. Channel 2 only engages while the footswitch is physically held.\n\nUseful for brief hits of drive or boost in a performance context.",
        "brothers-am/dip_pres_link_1": "PRES LINK 1 (Presence Link) — When ON, the Tone 1 knob simultaneously controls the Presence 1 setting. Creates a more open, transparent tonal response with greater range.\n\nEspecially useful with full-frequency instruments like synthesizers.",
        "brothers-am/dip_pres_link_2": "PRES LINK 2 (Presence Link) — When ON, the Tone 2 knob simultaneously controls the Presence 2 setting. Creates a more open, transparent sound with extended tonal range.",
        "brothers-am/dip_master": "MASTER — Converts Volume 2 into a global master output volume that controls overall level at all times, even when Channel 2 is bypassed.\n\nPrevents volume jumps when toggling channels on/off. With MASTER on, Volume 1 has no effect unless both channels are active simultaneously.",
        "brothers-am/dip_bank": "BANK — Accesses the alternate preset bank. Brothers AM stores two preset banks; toggling this dip switches between Bank A (default) and Bank B.\n\nUseful for organizing two completely different sets of four presets on the pedal's hardware memory.",

        // ─── MOOD MKII ────────────────────────────────────────────────────────

        // Knobs
        "time": "Wet Channel time control — behavior depends on selected mode:\n\n• REVERB: Controls both decay and size simultaneously. Higher = longer tail, more washed out. Quickly moving this knob while sounds are playing creates wild modulation effects.\n• DELAY: Sets delay time. Transitions cleanly between times without pitch-bending existing echoes — unlike most delays.\n• SLIP: Controls sampling window size. Lower = pitch-shifter feel with instant response. Higher = harmonized phrases trailing behind your playing.\n\nWith sync dip switch enabled: snaps to musical note divisions instead of continuous.",
        "mix": "Sets the overall wet/dry balance, controlling both the Wet Channel and Micro-Looper simultaneously. Full left = dry only; full right = all effect, no dry signal.\n\nImportant: When any ramping dip switch is engaged, this knob's function changes to control the ramp speed instead of the mix.",
        "length": "Micro-Looper length/size control — behavior depends on looper mode:\n\n• ENV: Slice size. Lower = microscopic grains; higher = short phrase repetition.\n• TAPE: Loop length. Turning counter-clockwise shortens a recorded loop, making it 'even more micro.'\n• STRETCH: Slice size. Higher settings = clearer phrase repetition; lower = blurry, grainy texture. Try counter-clockwise of noon for classic time-stretching sounds.",
        "modify_wet": "Wet Channel modulation — behavior depends on selected mode:\n\n• REVERB: Amount of 'smearing.' Full left = distinct multi-tap delay pattern; full right = smooth reverb; middle positions = unique hybrid textures.\n• DELAY: Feedback amount. At maximum, repeats pile up stably like a looper. Enables 'loop tricks' here.\n• SLIP: Playback speed and direction in semitone steps. Neutral center = no shift; forward = pitch up; reverse = pitch down.",
        "clock": "Sets MOOD's sample rate, simultaneously affecting both channels and maximum loop length.\n\n• Lower (2kHz): Lo-fi, gritty, ambient. Longer loops (~2 sec at 64k down to ~0.6 sec at 2k).\n• Higher (64kHz): Clean, hi-fi, crisp.\n\nMoves in discrete musical, harmonized steps by default. Enable the SMOOTH right-bank dip switch for a fluid, continuous sweep through sample rates.",
        "modify_loop": "Micro-Looper modulation — behavior depends on looper mode:\n\n• ENV: Audio detector sensitivity. Lower = less sensitive; higher = triggers on faint sounds.\n• TAPE: Playback speed and direction in octave steps (4x forward → 2x → 1x → 0.5x → 0.5x reverse → ... → 4x reverse).\n• STRETCH: Stretch amount and direction. Closer to center = slower progression. Maximum = no motion (loop freezes on current slice).",
        "ramp_speed": "Controls the speed of automated parameter ramping when a ramping dip switch is active. Slower values = gradual, sweeping movements. Faster values = rapid oscillation.\n\nNote: This replaces the Mix knob's wet/dry function while ramping is engaged.",

        // MOOD Toggles
        "wet_channel": "Selects the Wet Channel algorithm:\n\n• REVERB — Dense multi-tap ambience. Clusters of echoes that smear into a haze. Unique hybrid sounds available at positions between multi-tap and reverb.\n• DELAY — Clean looping delay. At max Modify (feedback), enables 'loop tricks' like self-stretching, micro-loop transfer, and double-time techniques.\n• SLIP — Auto-sampler. Continuously samples your input and replays it at a chosen speed/direction, generating whimsical harmonies and pitch effects.",
        "routing": "Controls what signal feeds into the Wet Channel (only has effect when both channels are active simultaneously):\n\n• IN (L>W) — Your dry guitar signal feeds the Wet Channel directly.\n• IN+LOOP (Parallel) — Both your dry signal and the Micro-Loop feed the Wet Channel together.\n• LOOP (W>L) — Only the Micro-Loop feeds the Wet Channel. Great for processing your loop through reverb, delay, or slip.",
        "micro_looper": "Selects the Micro-Looper algorithm:\n\n• ENV — Audio-controlled looper. Continuously records, chops loop into slices, and repeats the current slice while input signal is detected — creates dynamic stutters. Sensitivity set by Modify knob.\n• TAPE — Tape-style looper. Loop can be shortened with Length knob. Speed and direction (including reverse) set by Modify knob in octave steps.\n• STRETCH — Time-stretching looper. Explore loop details in slow motion, or spread short phrases into sprawling ambient textures.",
        "sync": "Hidden option — sync mode between channels:\n\n• OFF: Wet Channel and Micro-Looper operate independently.\n• Left position: Micro-Looper syncs to Wet Channel. Time knob sets loop length rhythmically.\n• Right position: Wet Channel syncs to Micro-Looper. Time knob moves in rhythmic steps relative to the loop length.",
        "spread": "Hidden option — SPREAD SOLO:\n\n• OFF: Stereo spread applies to both channels based on the SPREAD dip switch.\n• ON: Apply stereo spread to one channel only, keeping the other mono. Useful for a mono Micro-Loop running through a stereo (ping-pong) Wet effect.",
        "buffer_length": "Hidden option — LOOP LENGTH:\n\n• SHORT (Half): Cuts maximum loop length in half. Matches the behavior of the original MOOD MKI pedal.\n• LONG (Full): Standard MKII loop length.",

        // MOOD Footswitches
        "loop_bypass": "Toggles the Micro-Looper channel on/off.\n\n• Tap: Alternates between recording (LED blinks showing loop length) and playback (steady green LED).\n\nPhysical pedal hold action: Hold to engage OVERDUB mode (red LED) — records new audio layered onto the existing loop.\n\nThe 'Overdub' button in the panel below sends this action directly.",
        "wet_bypass": "Toggles the Wet Channel (Reverb/Delay/Slip) on/off.\n\n• Tap: Activates or bypasses the Wet Channel.\n\nPhysical pedal hold action: Hold to engage FREEZE mode — infinitely repeats and sustains the current sound as an ambient drone.\n\nThe 'Freeze' button in the panel below sends this action directly.",
        "freeze": "FREEZE — Infinitely sustains the current Wet Channel sound.\n\nPhysical pedal: Hold the Wet bypass footswitch.\n\n• In Reverb with Modify low: Creates a frozen percussive pattern you can manipulate by increasing Modify.\n• In Delay: Creates a secondary looping echo. Manipulate Modify to generate melodies and textures.\n• In Slip: Becomes a glitchy pitched synth. Move Modify to create chromatic melodies and arcade sounds.",
        "overdub": "OVERDUB — Records new audio layered onto the existing Micro-Loop (red LED).\n\nPhysical pedal: Hold the Loop bypass footswitch.\n\nMultiple overdubs accumulate. Use the FADE hidden option to gradually fade older layers for slowly evolving loops. The NO DUB dip switch switches to replace mode (zero feedback — each overdub replaces the loop).",
        "hidden_menu": "Opens the Hidden Options menu on the pedal's hardware display.\n\nPhysical pedal: Hold both footswitches simultaneously.\n\nAll hidden options (Stereo Width, Ramping Waveform, Fade, Tone, Level Balance, Direct Micro-Loop) are directly accessible in the panel below — no need to hold footswitches in this app.",
        "tap_tempo": "Sets the tempo by tapping. Send multiple taps in rhythm to establish a BPM.\n\nPhysical pedal: Hold a footswitch while turning the Time knob to exit tap tempo mode. MIDI clock, when active, will override tap tempo.",
        "stop_ramping": "Stops any active parameter ramping in place, freezing the current values. Useful for holding a sweep at a specific position during performance.",
        "factory_reset": "Resets all MOOD MKII settings to factory defaults.\n\nUse with caution — this clears all internal pedal settings. Physical pedal requires a specific button combination.",
        "midi_reset": "Resets MIDI-specific settings to defaults: MIDI clock ignore = OFF, octave transpose = +3 octaves, clock division = quarter note, portamento = 0, gate = 0.",

        // MOOD Hidden Options
        "stereo_width": "Sets the stereo panning width of the Wet Channel when the SPREAD right-bank dip switch is active.\n\nLower values = narrow stereo image; higher values = wider, more spread sound field.\n\nAccess on physical pedal: Hold both footswitches to open the hidden menu.",
        "ramping_waveform": "Selects the shape of automated parameter ramping movement:\n\n• Triangle (0): Linear back-and-forth sweep.\n• Sine (25): Smooth, natural wave oscillation.\n• Square (51): Instant jumps between two extreme positions — precise two-point movement.\n• Saw Up (76): Ramps up then snaps back to start.\n• Saw Down (102): Ramps down then snaps back.\n• Random (127): Unpredictable, random steps.\n\nShapes smoothly warp into one another between these values.",
        "fade": "Controls how quickly loops fade during overdubbing. Turning down causes loops to gradually fade while you add new layers — useful for slowly evolving ambient loops, or treating the Micro-Looper like a delay with natural decay.\n\nHas no effect when the NO DUB right-bank dip switch is active.",
        "tone": "A hi-cut (low-pass) filter applied to the Wet Channel algorithms. Useful for mellowing the effect to sit back in a mix, or replicating the warmer, darker character of the original MOOD. Full right = no filtering.",
        "level_balance": "Sets the relative loudness between the Wet Channel and the Micro-Looper channel. Useful when both channels are active and one overpowers the other.",
        "direct_micro_loop": "Blends the clean, unprocessed Micro-Loop signal back in when it's routed through the Wet Channel. Default is none (fully wet-processed). Increasing adds the direct loop alongside the processed version — helps maintain loop definition and clarity when routing through heavy reverb.",

        // MOOD Misc
        "midi_clock_ignore": "Controls whether MOOD MKII follows incoming MIDI clock:\n\n• LISTEN: Syncs to external MIDI clock for tempo-locked effects.\n• IGNORE: Ignores MIDI clock — use tap tempo or free-running independently.\n\nNote: MIDI clock is automatically ignored while in Synth Mode.",
        "clock_div_wet": "Clock division for the Wet Channel when synced to MIDI clock. Maps to musical note divisions:\n0=1/32, 18=1/16T, 36=1/16, 54=1/8T, 72=1/8, 90=1/4T, 108=1/4, 127=1/2",
        "clock_div_loop": "Clock division for the Micro-Looper when synced to MIDI clock. Maps to musical note divisions:\n0=1/32, 18=1/16T, 36=1/16, 54=1/8T, 72=1/8, 90=1/4T, 108=1/4, 127=1/2",
        "true_bypass": "Sets the bypass mode:\n\n• BUFFERED (default): Signal passes through a buffer when bypassed. The always-listening Micro-Looper continues to capture audio even while bypassed.\n• TRUE BYPASS: Completely analog signal path when bypassed. The always-listening looper will NOT function until you exit true bypass mode.",
        "synth_exit": "Exit Synth Mode — returns MOOD to normal operation. On physical pedal: simply move the Clock knob to exit Synth Mode.",

        // MOOD Synth Mode
        "synth_output": "In Synth Mode — determines how MOOD responds to incoming MIDI notes:\n\n• OPEN/MONO (0): Drone-like, constantly producing sound regardless of MIDI note state. Useful as a transposable ambient effect or pad.\n• ON/OFF (~1): Outputs sound only while a MIDI note is held. Instant attack and release.\n• ADSR (>1): Full synthesizer-style envelope. Enables swells, smooth decay, and dynamic response via Attack, Decay, Sustain, Release controls.",
        "synth_octave": "In Synth Mode — sets the octave transposition for incoming MIDI notes. Values 1–9 map to +1 through +9 octaves (+12 to +108 semitones). Controls which pitch range MOOD will respond to.",
        "synth_attack": "In Synth Mode (ADSR output) — attack time: how quickly the sound rises from silence to full volume after a MIDI note is played. Lower = snappy and immediate; higher = slow, swelling entrance.",
        "synth_decay": "In Synth Mode (ADSR output) — decay time: how quickly the sound falls from peak volume down to the sustain level after the initial attack.",
        "synth_sustain": "In Synth Mode (ADSR output) — sustain level: the volume maintained while a MIDI note is held, after the attack and decay phases complete.",
        "synth_release": "In Synth Mode (ADSR output) — release time: how long the sound takes to fade out completely after a MIDI note is released.",
        "synth_portamento": "In Synth Mode — glide (portamento) between consecutive MIDI notes. Higher values = slower, smoother pitch slide between notes. At zero = instant pitch jumps with no glide.",

        // MOOD Expression
        "mod_wheel": "Modulation Wheel control (MIDI CC 1). Standard MIDI modulation input. Can be used for expressive real-time control of Wet Channel parameters from a keyboard or controller.",
        "mood-mkii/expression": "Controls parameters via expression pedal or CV input (0–5V). Configure which parameters respond and the sweep direction/range using the Left Bank dip switches.",

        // MOOD Left Bank Dip Switches (CC 61–68 per MIDI manual)
        // These determine which knobs participate in expression/CV/ramping
        "mood-mkii/cc61": "LEFT BANK #1 — TIME knob expression/ramping participation.\n\nWhen ON, the Time knob responds to expression pedal, CV input, or the ramping function. Enables real-time time modulation for sweeping reverb tails, delay times, or sampling windows.\n\n⚠️ Note: App label may show a different name than the MIDI manual.",
        "mood-mkii/cc62": "LEFT BANK #2 — MODIFY (Wet Channel) expression/ramping participation.\n\nWhen ON, the Wet Channel Modify knob responds to expression/CV/ramp. Enables sweeping between multi-tap and reverb, feedback control, or pitch direction.\n\n⚠️ Note: App label may differ from MIDI manual.",
        "mood-mkii/cc63": "LEFT BANK #3 — CLOCK expression/ramping participation.\n\nWhen ON, the Clock (sample rate) knob responds to expression/CV/ramp. Enables dramatic lo-fi-to-hi-fi sweeps or sample-rate modulation.\n\n⚠️ Note: App label may differ from MIDI manual.",
        "mood-mkii/cc64": "LEFT BANK #4 — MODIFY (Micro-Looper) expression/ramping participation.\n\nWhen ON, the Loop Channel Modify knob responds to expression/CV/ramp. Enables real-time looper speed/direction changes or sensitivity sweeps.\n\n⚠️ Note: App label may differ from MIDI manual.",
        "mood-mkii/cc65": "LEFT BANK #5 — LENGTH expression/ramping participation.\n\nWhen ON, the Loop Length knob responds to expression/CV/ramp. Enables dynamic loop length or slice size modulation.\n\n⚠️ Note: App label may differ from MIDI manual.",
        "mood-mkii/cc66": "LEFT BANK #6 — BOUNCE.\n\nWhen ON, converts one-time ramping into continuous oscillation:\n• Without Bounce: Ramping happens once at power-on, then stops.\n• With Bounce: Continuous back-and-forth motion, like a tremolo applied to any knob.\n\n⚠️ Note: App label may differ from MIDI manual.",
        "mood-mkii/cc67": "LEFT BANK #7 — SWEEP range for expression/CV:\n\n• B (Bottom): Sweeps from minimum up to the current knob position.\n• T (Top): Sweeps from the current knob position up to maximum.\n\n⚠️ Note: App label may differ from MIDI manual.",
        "mood-mkii/cc68": "LEFT BANK #8 — POLARITY of expression/CV control:\n\n• F (Forward): Heel position = minimum, toe = maximum.\n• R (Reverse): Heel position = maximum, toe = minimum.\n\n⚠️ Note: App label may differ from MIDI manual.",

        // MOOD Right Bank Dip Switches (CC 71–78 per MIDI manual)
        // These are the feature/customization dips
        "mood-mkii/cc71": "CLASSIC — Replicates the quirks and unique character of the original MOOD pedal. Changes the Wet Channel algorithms to behave more like the first-generation pedal.\n\n⚠️ Note: App may show a different label — actual function per MIDI manual is Classic.",
        "mood-mkii/cc72": "MISO (Mono In, Stereo Out) — Takes your mono input signal and splits it into stereo output. Each channel processes independently for a wider stereo image.\n\n⚠️ Note: App may show a different label — actual function per MIDI manual is MISO.",
        "mood-mkii/cc73": "SPREAD — Enables full stereo processing for each Wet Channel algorithm. Each mode (Reverb/Delay/Slip) receives a unique stereo treatment, creating a wide, immersive sound field.\n\nUse the Stereo Width hidden option to control the panning width.\n\n⚠️ Note: App may show a different label — actual function per MIDI manual is Spread.",
        "mood-mkii/cc74": "DRY KILL — Removes the clean dry signal from MOOD's output entirely. Only the processed Wet Channel and Micro-Loop are heard. Useful in parallel effects loops or four-cable method setups.\n\n⚠️ Note: App may show a different label — actual function per MIDI manual is Dry Kill.",
        "mood-mkii/cc75": "TRAILS — When ON, Wet Channel effects fade out naturally after the pedal is bypassed (buffered bypass behavior). When OFF, effects cut immediately on bypass.\n\n⚠️ Note: App may show a different label — actual function per MIDI manual is Trails.",
        "mood-mkii/cc76": "LATCH — The Loop bypass footswitch stays engaged until pressed again (latched toggle mode). Without Latch: footswitch is momentary — hold to record, release to play. With Latch: press once to start, press again to stop. Useful for hands-free looping.\n\n⚠️ Note: App may show a different label — actual function per MIDI manual is Latch.",
        "mood-mkii/cc77": "NO DUB (Refresh Mode) — Sets Micro-Looper feedback to zero during overdub. Instead of layering new audio onto the existing loop, each overdub completely replaces it. Treats the looper more like an auto-sampler or live-refresh device.\n\n⚠️ Note: App may show a different label — actual function per MIDI manual is No Dub.",
        "mood-mkii/cc78": "SMOOTH — Removes the stepped behavior from the Clock knob. Without Smooth: Clock moves in discrete, harmonically-related sample-rate steps. With Smooth: fluid, continuous sweep through all sample rates.\n\n⚠️ Note: App may show a different label — actual function per MIDI manual is Smooth.",

        // Shared / Generic
        "expression": "Controls parameters via expression pedal or CV input (0–5V, never exceed). Configure which knobs respond using the dip switches. Range 0–127.",
    ]
}

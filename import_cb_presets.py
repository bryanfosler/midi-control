#!/usr/bin/env python3
"""
Import community presets from the Chase Bliss Presets app backup JSON
into the MIDIControl app preset directory.

All imported presets are tagged "cb-presets" so they can be identified
and removed before shipping to the App Store.

Usage:
    python3 import_cb_presets.py [--dry-run]
"""

import json
import uuid
import os
import sys
from datetime import datetime, timezone

# ── Configuration ────────────────────────────────────────────────────────────

SOURCE_FILE = os.path.expanduser("~/Downloads/ChaseBlissPresets.json")
PRESETS_DIR = os.path.expanduser("~/Library/Application Support/MIDIControl/presets")
SOURCE_TAG   = "cb-presets"
IMPORT_DATE  = "2026-03-01T00:00:00Z"

# Factory preset names to skip (community recreations with same names)
FACTORY_BAM_NAMES = {
    "The Analog Man", "Sunny Skies", "2-In-1", "Bad Bros",
}

# ── CC Mappings ───────────────────────────────────────────────────────────────

# Brothers AM (brothers-am, MIDI channel 2)
BAM_KNOB_CC = {
    "topLeft":      14,   # Gain 2
    "topMiddle":    15,   # Vol 2
    "topRight":     16,   # Gain 1
    "bottomLeft":   17,   # Tone 2
    "bottomMiddle": 18,   # Vol 1
    "bottomRight":  19,   # Tone 1
}
BAM_TOGGLE_CC = {
    "left":   21,   # Gain 2 Type  (Boost / OD / Dist)
    "middle": 22,   # Treble Boost (☀ / Off / ○)
    "right":  23,   # Gain 1 Type  (Dist / OD / Boost)
}
BAM_TOGGLE_VALUES = {"left": 0, "middle": 2, "right": 3}

BAM_HIDDEN_KNOB_CC = {
    "bottomLeft":  27,   # Presence 2
    "bottomRight": 29,   # Presence 1
}

# MOOD MKII (mood-mkii, MIDI channel 3)
MOOD_KNOB_CC = {
    "topLeft":      14,   # Time
    "topMiddle":    15,   # Mix
    "topRight":     16,   # Length
    "bottomLeft":   17,   # Modify (Wet)
    "bottomMiddle": 18,   # Clock
    "bottomRight":  19,   # Modify (Loop)
}
MOOD_TOGGLE_CC = {
    "left":   21,   # Wet Channel   (Reverb / Delay / Slip)
    "middle": 22,   # Routing       (In / In+Loop / Loop)
    "right":  23,   # Micro-Looper  (ENV / Tape / Stretch)
}
MOOD_TOGGLE_VALUES = {"left": 0, "middle": 2, "right": 127}

MOOD_HIDDEN_KNOB_CC = {
    "topLeft":      24,   # Stereo Width
    "topMiddle":    25,   # Ramping Waveform
    "topRight":     26,   # Fade
    "bottomLeft":   27,   # Tone
    "bottomMiddle": 28,   # Level Balance
    "bottomRight":  29,   # Direct Micro-Loop
}
MOOD_HIDDEN_TOGGLE_CC   = {
    "toggleLeft":   31,   # Sync   (Loop→Wet / Off / Wet→Loop)
    "toggleMiddle": 32,   # Spread (Wet / Both / Loop)
}
# Buffer Length (CC 33) is 2-option: left=0 (MKI), right=127 (Full)
MOOD_BUFFER_LENGTH_CC   = 33
MOOD_HIDDEN_TOGGLE_VALUES = {"left": 0, "middle": 2, "right": 127}
MOOD_BUFFER_VALUES        = {"left": 0, "right": 127}

# ── Dip switch mapping (same layout for both pedals) ─────────────────────────
# row1 dip 1-8 → CC 61-68  (Control / Left bank)
# row2 dip 1-8 → CC 71-78  (Customize / Right bank)
ROW1_CC_BASE = 61
ROW2_CC_BASE = 71


# ── Conversion helpers ────────────────────────────────────────────────────────

def convert_dips(dip_section: dict, cc_base: int) -> dict:
    """Convert a dip row {"1": bool, …, "8": bool} to {cc: 0|127}."""
    params = {}
    for dip_key, dip_on in dip_section.items():
        cc = cc_base + int(dip_key) - 1   # "1" → base+0, "2" → base+1, …
        params[cc] = 127 if dip_on else 0
    return params


def convert_brothers_am(src: dict) -> dict:
    params = {}

    # Main knobs
    for pos, cc in BAM_KNOB_CC.items():
        val = src.get("knobValues", {}).get(pos)
        if val is not None:
            params[cc] = int(val)

    # Toggle switches
    for pos, cc in BAM_TOGGLE_CC.items():
        raw = src.get("toggleSwitchValues", {}).get(pos)
        if raw in BAM_TOGGLE_VALUES:
            params[cc] = BAM_TOGGLE_VALUES[raw]

    # Dip switches
    dips = src.get("dipswitchValues", {})
    if "row1" in dips:
        params.update(convert_dips(dips["row1"], ROW1_CC_BASE))
    if "row2" in dips:
        params.update(convert_dips(dips["row2"], ROW2_CC_BASE))

    # Hidden options: Presence knobs only
    hidden = src.get("hiddenOptionValues", {})
    for pos, cc in BAM_HIDDEN_KNOB_CC.items():
        val = hidden.get(pos)
        if val is not None:
            params[cc] = int(val)

    return params


def convert_mood_mkii(src: dict) -> dict:
    params = {}

    # Main knobs
    for pos, cc in MOOD_KNOB_CC.items():
        val = src.get("knobValues", {}).get(pos)
        if val is not None:
            params[cc] = int(val)

    # Toggle switches
    for pos, cc in MOOD_TOGGLE_CC.items():
        raw = src.get("toggleSwitchValues", {}).get(pos)
        if raw in MOOD_TOGGLE_VALUES:
            params[cc] = MOOD_TOGGLE_VALUES[raw]

    # Ramp Speed (CC 20)
    ramp = src.get("rampValue")
    if ramp is not None:
        params[20] = int(ramp)

    # Dip switches
    dips = src.get("dipswitchValues", {})
    if "row1" in dips:
        params.update(convert_dips(dips["row1"], ROW1_CC_BASE))
    if "row2" in dips:
        params.update(convert_dips(dips["row2"], ROW2_CC_BASE))

    # Hidden option knobs
    hidden = src.get("hiddenOptionValues", {})
    for pos, cc in MOOD_HIDDEN_KNOB_CC.items():
        val = hidden.get(pos)
        if val is not None:
            params[cc] = int(val)

    # Hidden option toggles (3-way)
    for pos, cc in MOOD_HIDDEN_TOGGLE_CC.items():
        raw = hidden.get(pos)
        if raw in MOOD_HIDDEN_TOGGLE_VALUES:
            params[cc] = MOOD_HIDDEN_TOGGLE_VALUES[raw]

    # Buffer Length (2-way: left=MKI, right=Full)
    buf_raw = hidden.get("toggleRight")
    if buf_raw in MOOD_BUFFER_VALUES:
        params[MOOD_BUFFER_LENGTH_CC] = MOOD_BUFFER_VALUES[buf_raw]

    return params


def build_preset(src: dict, pedal_id: str, midi_channel: int,
                 params: dict, skip_names: set):
    name = src.get("name", "Untitled").strip()

    # Skip factory name overlaps (case-insensitive)
    if pedal_id == "brothers-am" and name.lower() in {s.lower() for s in skip_names}:
        return None

    note_parts = []
    note = src.get("publicNote", "").strip()
    if note:
        note_parts.append(note)
    creator = src.get("displayName", "").strip()
    if creator:
        note_parts.append(f"Shared by {creator} via CB Presets app.")

    preset_id = str(uuid.uuid4()).upper()
    return {
        "id":          preset_id,
        "name":        name,
        "pedalId":     pedal_id,
        "midiChannel": midi_channel,
        "parameters":  {str(cc): val for cc, val in sorted(params.items())},
        "notes":       "  ".join(note_parts),
        "tags":        [SOURCE_TAG],
        "createdAt":   IMPORT_DATE,
        "updatedAt":   IMPORT_DATE,
    }


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    dry_run = "--dry-run" in sys.argv

    with open(SOURCE_FILE) as f:
        data = json.load(f)

    community = data.get("communityPresets", [])

    results = {"brothers-am": [], "mood-mkii": []}

    for src in community:
        pedal = src.get("pedal")

        if pedal == "brothersAM":
            params = convert_brothers_am(src)
            preset = build_preset(src, "brothers-am", 2, params, FACTORY_BAM_NAMES)
            if preset:
                results["brothers-am"].append(preset)

        elif pedal == "moodMKII":
            params = convert_mood_mkii(src)
            preset = build_preset(src, "mood-mkii", 3, params, set())
            if preset:
                results["mood-mkii"].append(preset)

    # Report
    total = sum(len(v) for v in results.values())
    print(f"Presets to import: {total}")
    for pedal_id, presets in results.items():
        print(f"  {pedal_id}: {len(presets)}")
    print()

    if dry_run:
        print("DRY RUN — showing first preset per pedal:\n")
        for pedal_id, presets in results.items():
            if presets:
                print(f"--- {pedal_id} ---")
                print(json.dumps(presets[0], indent=2))
                print()
        return

    # Write files
    for pedal_id, presets in results.items():
        out_dir = os.path.join(PRESETS_DIR, pedal_id)
        os.makedirs(out_dir, exist_ok=True)
        for preset in presets:
            path = os.path.join(out_dir, f"{preset['id']}.json")
            with open(path, "w") as f:
                json.dump(preset, f, indent=2, sort_keys=True)
        print(f"Wrote {len(presets)} presets → {out_dir}")

    print("\nDone. Restart MIDIControl to see imported presets.")
    print(f"To remove before shipping: delete all presets tagged \"{SOURCE_TAG}\".")


if __name__ == "__main__":
    main()

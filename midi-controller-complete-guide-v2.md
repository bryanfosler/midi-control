# DIY Pi-Powered MIDI Controller
## Complete Build Guide for Chase Bliss Brothers & Mood MK2

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Complete Shopping List](#2-complete-shopping-list)
3. [Phase 1: Pi Basics](#3-phase-1-pi-basics)
4. [Phase 2: Bluetooth MIDI](#4-phase-2-bluetooth-midi)
5. [Phase 3: DIY MIDI Splitter](#5-phase-3-diy-midi-splitter)
6. [Phase 4: Enclosure & Integration](#6-phase-4-enclosure--integration)
7. [Phase 5: Footswitches (Future)](#7-phase-5-footswitches-future)
8. [MIDI Reference](#8-midi-reference)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Project Overview

### What You're Building

A clean, portable MIDI hub that:
- Receives Bluetooth MIDI from your iPhone (CB Presets app)
- Receives MIDI from your Mac (via Bluetooth or USB)
- Outputs TRS MIDI to up to 4 Chase Bliss pedals (or any mix of Ring/Tip Active)
- Is expandable for footswitches later

### Your Pedals

| Pedal | MIDI Jack | TRS Type | Notes |
|-------|-----------|----------|-------|
| Chase Bliss Brothers | 1/4" (6.35mm) TRS | Ring Active | Overdrive/fuzz |
| Chase Bliss Mood MK2 | 1/4" (6.35mm) TRS | Ring Active | Granular looper |

### Signal Flow

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────────┐
│  iPhone         │     │  Raspberry Pi   │     │  CME C2MIDI Pro     │
│  CB Presets App │────▶│  (Bluetooth     │────▶│  USB MIDI Interface │
│                 │ BT  │   MIDI Server)  │ USB │                     │
└─────────────────┘     └─────────────────┘     └──────────┬──────────┘
                              ▲                            │
┌─────────────────┐           │                     5-pin DIN MIDI
│  Mac/Computer   │───────────┘                            │
│  (via BT or USB)│  Bluetooth                             ▼
└─────────────────┘                          ┌─────────────────────────┐
                                             │    DIY 4-Output         │
                                             │    Configurable Splitter│
                                             │                         │
                                             │  ┌──┐ ┌──┐ ┌──┐ ┌──┐    │
                                             │  │◀■│ │◀■│ │ ■▶│ │ ■▶│   │
                                             │  └──┘ └──┘ └──┘ └──┘    │
                                             │   1    2    3    4      │
                                             │   │    │    │    │      │
                                             └───┼────┼────┼────┼──────┘
                                                 │    │    │    │
                                                 ▼    ▼    ▼    ▼
                                             Brothers Mood  (future)
```

### Why This Design?

**Interview-ready talking points:**
- "I chose a Raspberry Pi over a dedicated Bluetooth adapter because I wanted a programmable hub that could grow with my needs"
- "I built a configurable MIDI splitter with SPDT switches that supports both Ring Active (Chase Bliss) and Tip Active (Strymon/Meris) pedals"
- "The CME C2MIDI Pro gives me USB-C native for my Mac and Pi compatibility with one device"
- "The modular design means I can add footswitches or web control without starting over"

---

## 2. Complete Shopping List

### Raspberry Pi Setup (~$112-117)

| Item | Price | Link/Notes |
|------|-------|------------|
| **Raspberry Pi 5 (8GB)** | ~$80 | [Adafruit](https://www.adafruit.com/product/5813) or Amazon |
| **Pi 5 Power Supply (27W USB-C)** | ~$12 | Official Raspberry Pi power supply required |
| **MicroSD Card (32GB+ A2)** | ~$10 | Samsung EVO Select or SanDisk Extreme |
| **Pi 5 Active Cooler** | ~$10-15 | Basic heatsink is fine; active cooling recommended |

**Note:** Pi 5 needs a 5V/5A (27W) power supply. Don't skimp here — underpowered Pi = random crashes.

### USB MIDI Interface (~$35-38)

| Item | Price | Link | Notes |
|------|-------|------|-------|
| **CME C2MIDI Pro** | $30 | [CME Direct](https://www.cme-pro.com/product/c2midi-pro/) | USB-C native, free US shipping |
| **USB-C to USB-A Adapter** | ~$5-8 | Amazon | For connecting to Pi 5's USB-A ports |

**Why C2MIDI Pro:**
- USB-C native (plugs directly into MacBook)
- $30 vs $45 for Roland UM-ONE
- High quality (CME is MIDI Association board member)
- Class-compliant (no drivers needed)
- Handles SysEx reliably
- Outputs 5-pin DIN (connects to your splitter)

### DIY 4-Output Configurable Splitter (~$50-55)

#### Connectors

| Item | Qty | Price | Link | Notes |
|------|-----|-------|------|-------|
| **5-Pin DIN Female Jack (Panel Mount)** | 1 (10-pack) | ~$8 | [Amazon](https://www.amazon.com/Xiaoyztan-Chassis-Connector-Monitor-Computer/dp/B07NY6Z2N7) | MIDI input |
| **1/4" TRS Female Jacks (Panel Mount)** | 4 | ~$10 | [Amazon - GLS Audio 4-pack](https://www.amazon.com/GLS-Audio-Jacks-Female-Stereo/dp/B00CO6Q1II) | Outputs to pedals |

#### Switches (True SPDT - 3 Pin)

| Item | Qty | Price | Link | Notes |
|------|-----|-------|------|-------|
| **Mini SPDT Slide Switches (SS12D10 + SS12F15)** | 4 needed (40-pack) | ~$7 | [Amazon - DAOKI](https://www.amazon.com/DAOKI-DR-US-486-P/dp/B08SLPBTW6) | True SPDT, 3-pin, 2-position |

**Why these switches:**
- True SPDT (3 pins per switch) — center is Common, left is Position 1, right is Position 2
- Physically can only be in ONE position at a time (no "both on" errors)
- Easy to see current position at a glance
- 2.54mm pin pitch — breadboard compatible for testing
- You get 40 for ~$7 (plenty of spares)

#### Enclosure

| Item | Qty | Price | Link | Notes |
|------|-----|-------|------|-------|
| **Hammond 1590B Enclosure** | 1 | ~$12-15 | [Amazon](https://www.amazon.com/s?k=hammond+1590b+enclosure) or [Tayda](https://www.taydaelectronics.com/) | Aluminum, ~4.4" x 2.3" x 1.2" |

#### Wire & Supplies

| Item | Price | Link | Notes |
|------|-------|------|-------|
| **Hookup Wire (22 AWG, solid core)** | ~$8-10 | Amazon | Get assorted colors |
| **Heat Shrink Tubing** | ~$5-6 | Amazon | Assorted sizes |

### Cables (~$20-35)

| Item | Qty | Price | Link | Notes |
|------|-----|-------|------|-------|
| **MIDI Cable (5-pin DIN, 3-6ft)** | 1 | ~$8 | Amazon | C2MIDI Pro → Splitter |
| **1/4" TRS Cables** | 2-4 | ~$15-25 | Amazon | Splitter → Pedals (you may have some) |

### Prototyping Supplies (~$15-40)

| Item | Price | Link | Notes |
|------|-------|------|-------|
| **Breadboard (half or full size)** | ~$6-8 | Amazon | Test before soldering |
| **Jumper Wire Kit** | ~$7-10 | Amazon | M-M, M-F, F-F assortment |
| **Multimeter** | ~$15-20 | Amazon | Skip if you have one |

### Total Estimated Cost

| Category | Low | High |
|----------|-----|------|
| Raspberry Pi Setup | $112 | $117 |
| CME C2MIDI Pro + Adapter | $35 | $38 |
| DIY Splitter (4-output, configurable) | $50 | $55 |
| Cables | $20 | $35 |
| Prototyping | $15 | $40 |
| **TOTAL** | **$232** | **$285** |

**Compare to buying off-the-shelf:**
- CME WIDI Jack: $70
- Morningstar MIDI Box (2 outputs): $80
- No configurability, no expansion

You're paying more for a fully programmable, 4-output, configurable system AND the knowledge to build/modify it.

---

## 3. Phase 1: Pi Basics

**Goal:** Get your Pi running headless (no monitor/keyboard) and SSH in from your Mac.

**Time:** 1-2 hours

### Step 1: Flash the SD Card

1. Download [Raspberry Pi Imager](https://www.raspberrypi.com/software/) on your Mac
2. Insert your microSD card
3. Open Imager and select:
   - **Device:** Raspberry Pi 5
   - **OS:** Raspberry Pi OS (64-bit) — the full desktop version is fine
   - **Storage:** Your SD card

4. **Click the gear icon (⚙️) BEFORE writing** — this is important!
   - Set hostname: `bryanfoslerpi5`
   - Enable SSH: Yes, use password authentication
   - Set username: `bfosler`
   - Set password: Something you'll remember
   - Configure WiFi: Enter your home network SSID and password
   - Set locale: Your timezone

5. Write the image (takes 5-10 minutes)

### Step 2: First Boot

1. Insert SD card into Pi
2. Connect power
3. Wait 2-3 minutes for first boot (the Pi is expanding the filesystem and configuring itself)

### Step 3: Find Your Pi on the Network

Open Terminal on your Mac and try:

```bash
# Method 1: mDNS (usually works)
ping bryanfoslerpi5.local

# Method 2: If that doesn't work, scan your network
# First, find your Mac's IP to know your network range
ipconfig getifaddr en0

# Then scan (replace 192.168.1 with your actual network)
arp -a | grep -i "raspberry\|b8:27\|dc:a6\|e4:5f"
```

### Step 4: SSH In

```bash
ssh bfosler@bryanfoslerpi5.local
# Enter the password you set in Imager
```

**You should see a command prompt like:**
```
bfosler@bryanfoslerpi5:~ $
```

🎉 **Congratulations!** You're now controlling your Pi remotely.

### Step 5: Basic Setup Commands

Run these to update your Pi and install some tools we'll need:

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install helpful tools
sudo apt install -y git python3-pip vim htop

# Check Python version (should be 3.11+)
python3 --version

# Enable Bluetooth (should already be enabled, but just in case)
sudo systemctl enable bluetooth
sudo systemctl start bluetooth
```

### Step 6: Test Bluetooth

```bash
# Check Bluetooth is working
bluetoothctl
# You should see a prompt like [bluetooth]#

# Type these commands:
power on
agent on
scan on
# You should see nearby Bluetooth devices appearing

# Exit with:
exit
```

### What You Learned

- Headless Pi setup (no monitor needed)
- SSH remote access
- Basic Linux commands (`apt`, `systemctl`, `sudo`)
- Bluetooth fundamentals

### Checkpoint

✅ Pi boots and connects to WiFi  
✅ You can SSH in from your Mac  
✅ Bluetooth is working  

---

## 4. Phase 2: Bluetooth MIDI

**Goal:** Receive MIDI from your iPhone's CB Presets app on the Pi.

**Time:** 2-4 hours (includes troubleshooting)

### Understanding Bluetooth MIDI

Bluetooth MIDI (BLE-MIDI) is different from regular Bluetooth audio. It's a low-latency protocol specifically designed for musical instruments. Your iPhone supports it natively, and with the right software, so does the Pi.

### Step 1: Install BlueZ MIDI Support

BlueZ is Linux's Bluetooth stack. We need to configure it for MIDI:

```bash
# Install ALSA MIDI tools
sudo apt install -y bluez bluez-tools libasound2-plugins alsa-utils

# Install Python MIDI libraries
pip3 install mido python-rtmidi --break-system-packages
```

### Step 2: Connect USB MIDI Interface

Connect your CME C2MIDI Pro (via USB-C to USB-A adapter) to the Pi:

```bash
# List connected MIDI devices
aconnect -l

# You should see something like:
# client 20: 'C2MIDI Pro' [type=kernel,card=1]
#     0 'C2MIDI Pro MIDI 1'
```

### Step 3: Create a Simple MIDI Monitor

Let's write a Python script to see incoming MIDI messages:

```bash
# Create a test script
nano ~/midi_monitor.py
```

Paste this code:

```python
#!/usr/bin/env python3
"""
Simple MIDI monitor - shows all incoming MIDI messages
"""
import mido

# List available MIDI ports
print("Available MIDI inputs:")
for port in mido.get_input_names():
    print(f"  - {port}")

# Open the first available input (or specify by name)
if mido.get_input_names():
    port_name = mido.get_input_names()[0]
    print(f"\nListening on: {port_name}")
    print("Send MIDI messages to see them here. Press Ctrl+C to exit.\n")
    
    with mido.open_input(port_name) as inport:
        for msg in inport:
            print(msg)
else:
    print("No MIDI inputs found! Connect a USB MIDI interface.")
```

Save (Ctrl+O, Enter) and exit (Ctrl+X), then run:

```bash
python3 ~/midi_monitor.py
```

### Step 4: Set Up Bluetooth MIDI

For studio use, Network MIDI is actually easier and more reliable than Bluetooth:

```bash
# Install rtpmidi
sudo apt install -y rtpmidi

# Start rtpmidi server
rtpmidid &
```

Then on your Mac, open **Audio MIDI Setup** > **MIDI Studio** > **Network** and you'll see your Pi!

### Alternative: Full BLE-MIDI Setup

For true Bluetooth MIDI from your iPhone, see the [bluez-midi project](https://github.com/oxesoft/bluez-midi).

### What You Learned

- Bluetooth LE vs Classic Bluetooth
- ALSA and Linux audio architecture
- MIDI routing with `aconnect`
- Python MIDI programming with `mido`

### Checkpoint

✅ USB MIDI interface detected by Pi  
✅ Can monitor MIDI messages in Python  
✅ (Optional) Network MIDI working between Mac and Pi  

---

## 5. Phase 3: DIY MIDI Splitter

**Goal:** Build a 4-output, configurable MIDI splitter that supports both Ring Active (Chase Bliss) and Tip Active (Strymon/Meris/Empress) pedals.

**Time:** 2-4 hours (including soldering)

### Understanding MIDI Electrically

MIDI is just serial data at 31.25 kbaud. The electrical spec:
- **Current loop:** 5mA flows through an optocoupler in the receiving device
- **Voltage:** Source provides ~5V through a 220Ω resistor

**TRS MIDI Configurations:**

| Configuration | MIDI Signal On | Used By |
|---------------|----------------|---------|
| **Ring Active** | Ring | Chase Bliss |
| **Tip Active** | Tip | Strymon, Meris, Empress, Alexander |

Your DIY splitter will handle BOTH with configurable SPDT switches per output.

### SPDT Slide Switch Operation

Each switch has 3 pins:

```
    Position LEFT              Position RIGHT
    (Ring Active)              (Tip Active)
    
       ┌────┐                    ┌────┐
       │◀■  │                    │  ■▶│
       └──┬─┘                    └──┬─┘
          │                         │
      1   C   2                 1   C   2
      ├───┤                         ├───┤
      └─┬─┘                         └─┬─┘
    connected                     connected

Pin 1 = Ring (left position) → Chase Bliss
Pin C = Common (center) → MIDI Signal from DIN Pin 5
Pin 2 = Tip (right position) → Strymon, Meris, Empress
```

**How it works:** The center pin (Common) receives the MIDI signal. When you slide left, signal goes to Pin 1 (Ring). When you slide right, signal goes to Pin 2 (Tip). **Physically impossible to be in both positions.**

### Full Wiring Diagram

```
                             4x SPDT SLIDE SWITCHES
                            ┌──┐ ┌──┐ ┌──┐ ┌──┐
5-Pin DIN Input             │■ │ │■ │ │ ■│ │ ■│
(from CME C2MIDI Pro)       └┬─┘ └┬─┘ └┬─┘ └┬─┘
                             │    │    │    │
  Pin 5 (Signal) ────────────┼────┼────┼────┤
                             │    │    │    │
                             C    C    C    C  (Common pins)
                            ╱╲   ╱╲   ╱╲   ╱╲
                           1  2 1  2 1  2 1  2
                           │  │ │  │ │  │ │  │
                           ▼  ▼ ▼  ▼ ▼  ▼ ▼  ▼
                           R  T R  T R  T R  T
                           │  │ │  │ │  │ │  │
                           └──┴─┴──┴─┴──┴─┴──┘
                               │    │    │    │
                              TRS  TRS  TRS  TRS
                              OUT1 OUT2 OUT3 OUT4
                               │    │    │    │
                               R=Ring, T=Tip on each jack

  Pin 2 (Ground) ──────────────────────────────► All TRS Sleeves


5-Pin DIN Pinout (looking at solder side):
    ┌───────┐
   /  1   2  \      Pin 1: Not used
  │     3     │     Pin 2: Ground/Shield ──► All TRS Sleeves
  │  4     5  │     Pin 3: Not used
   \─────────/      Pin 4: Not used (current source in transmitter)
                    Pin 5: MIDI Data ──► All Switch Common pins
```

### TRS Jack Wiring Detail

For each 1/4" TRS jack:

```
              TRS Jack (rear view)
                    
                  ┌─────┐
            Tip ──┤     │◄── From Switch Pin 2 (Tip Active)
                  │     │
           Ring ──┤     │◄── From Switch Pin 1 (Ring Active)
                  │     │
         Sleeve ──┤     │◄── From DIN Pin 2 (Ground)
                  └─────┘
```

### Enclosure Layout — Option B

TRS output cables exit the long side face. MIDI cables connect at the short end.
Switches sit on top for set-and-forget Ring/Tip configuration per output.

```
SHORT SIDE A (60mm × 31mm) — MIDI Connections
┌──────────────────────────────────┐
│                                  │
│       ◎              ◎          │
│     DIN IN         DIN THRU      │
│                                  │
└──────────────────────────────────┘

LONG SIDE (112mm × 31mm) — TRS Outputs
┌──────────────────────────────────────────────────────┐
│                                                      │
│    ○           ○           ○           ○            │
│   TRS 1       TRS 2       TRS 3       TRS 4         │
│                                                      │
└──────────────────────────────────────────────────────┘

TOP FACE (112mm × 60mm) — Config Switches
┌──────────────────────────────────────────────────────┐
│                                                      │
│                                                      │
│   [SW1]      [SW2]      [SW3]      [SW4]            │
│    1          2          3          4               │
│                                                      │
│   ◀ LEFT = RING Active (Chase Bliss)                │
│     RIGHT ▶ = TIP Active (Strymon / Meris)          │
│                                                      │
└──────────────────────────────────────────────────────┘

SHORT SIDE B — blank (reserved for power jack if added later)
```

### 1590B Drilling & Wire Reference

#### Drilling Templates — Three Faces

Three faces require drilling. Use a center punch before every hole.

---

**FACE 1 — Short Side A (60mm × 31mm): MIDI Connectors**

```
◄──────────── 60mm ─────────────►
┌────────────────────────────────┐  ▲
│                                │  │
│      ◎              ◎         │  31mm
│    5/8"            5/8"        │  │
│   DIN IN         DIN THRU      │  ▼
└────────────────────────────────┘
    18mm              42mm
    (all holes centered vertically at 15mm from bottom)
```

---

**FACE 2 — Long Side (112mm × 31mm): TRS Outputs**

```
◄─────────────────── 112mm ──────────────────────►
┌──────────────────────────────────────────────────┐  ▲
│                                                  │  │
│    ●         ●         ●         ●               │  31mm
│   3/8"      3/8"      3/8"      3/8"             │  │
│   TRS 1    TRS 2    TRS 3    TRS 4               │  ▼
└──────────────────────────────────────────────────┘
   16mm       38mm      60mm      82mm
   (all holes centered vertically at 15mm from bottom)
```

---

**FACE 3 — Top Face (112mm × 60mm): Config Switches**

```
◄─────────────────── 112mm ──────────────────────►
┌──────────────────────────────────────────────────┐  ▲
│                                                  │  │
│                                                  │  │
│   [ ]       [ ]       [ ]       [ ]              │  60mm
│   SW 1     SW 2     SW 3     SW 4               │  │
│                                                  │  │
│                                                  │  ▼
└──────────────────────────────────────────────────┘
  16mm        38mm       60mm       82mm
  (switches centered at 30mm from either long edge)
  (x positions aligned above TRS jacks on long side)
```

  ●  = Round hole (step bit)
  ◎  = Round hole, larger (step bit — 5/8")
  [ ] = Slot for switch knob (~3mm × 8mm — drill + file, or Dremel)

> Tip: Use a center punch on each mark before drilling to keep the bit from skating on the aluminum.

#### Hole Sizes

| Component | Hole Size | Qty | Face |
|-----------|-----------|-----|------|
| 5-pin DIN IN jack | **5/8" (16mm)** | 1 | Short Side A |
| 5-pin DIN THRU jack | **5/8" (16mm)** | 1 | Short Side A |
| 1/4" TRS jack | **3/8" (9.5mm)** | 4 | Long Side |
| Slide switch slot | **~3mm × 8mm slot** | 4 | Top Face |

---

#### Wire Cut Sheet

Cut all wires before soldering. Strip 1/4" (~6mm) off each end.

| # | Color | Length | From | To |
|---|-------|--------|------|----|
| 1 | **Black** | 5" | DIN IN Pin 2 | TRS 1 Sleeve |
| 2 | **Black** | 3" | TRS 1 Sleeve | TRS 2 Sleeve |
| 3 | **Black** | 3" | TRS 2 Sleeve | TRS 3 Sleeve |
| 4 | **Black** | 3" | TRS 3 Sleeve | TRS 4 Sleeve |
| 5 | **Red** | 5" | DIN IN Pin 5 | SW 1 Common (C) |
| 6 | **Red** | 2" | SW 1 Common | SW 2 Common |
| 7 | **Red** | 2" | SW 2 Common | SW 3 Common |
| 8 | **Red** | 2" | SW 3 Common | SW 4 Common |
| 9 | **White** | 3" | SW 1 Pin 1 | TRS 1 Ring |
| 10 | **White** | 3" | SW 2 Pin 1 | TRS 2 Ring |
| 11 | **White** | 3" | SW 3 Pin 1 | TRS 3 Ring |
| 12 | **White** | 3" | SW 4 Pin 1 | TRS 4 Ring |
| 13 | **Yellow** | 3" | SW 1 Pin 2 | TRS 1 Tip |
| 14 | **Yellow** | 3" | SW 2 Pin 2 | TRS 2 Tip |
| 15 | **Yellow** | 3" | SW 3 Pin 2 | TRS 3 Tip |
| 16 | **Yellow** | 3" | SW 4 Pin 2 | TRS 4 Tip |
| 17 | **Red** | 2" | DIN IN Pin 5 | DIN THRU Pin 5 |
| 18 | **Black** | 2" | DIN IN Pin 2 | DIN THRU Pin 2 |

**Total: 18 wires.** Wires 17–18 are the passive MIDI Thru tap — no additional components needed. Cut a couple extra 3" blacks in case you need slack on the ground bus.

#### Color Legend

```
BLACK  ─── Ground        DIN Pin 2 → all TRS Sleeves (daisy-chained)
RED    ─── MIDI Signal   DIN Pin 5 → all Switch Commons (daisy-chained)
WHITE  ─── Ring output   Switch Pin 1 → TRS Ring    (Chase Bliss = LEFT)
YELLOW ─── Tip output    Switch Pin 2 → TRS Tip     (Strymon/Meris = RIGHT)
```

#### Solder Point Map

```
DIN JACK (solder side, looking in from back of panel)

   /  1   2  \
  │     3     │   Pin 2 (Ground) ──► BLACK wires  ──► all TRS Sleeves
  │  4     5  │   Pin 5 (Signal) ──► RED wires    ──► all Switch C pins
   \─────────/


SPDT SWITCH (bottom, 3 solder pins)

  ┌─────────────────┐
  │   1     C     2 │
  └───┬─────┬─────┬─┘
      │     │     │
    WHITE   RED  YELLOW
    (Ring) (Sig) (Tip)
      │     │     │
      ▼     ▼     ▼
    TRS   DIN   TRS
    Ring  Pin 5  Tip


TRS JACK (rear, 3 solder lugs)

  ┌──────────────────┐
  │ Tip    ◄── YELLOW (from Switch Pin 2)  │
  │ Ring   ◄── WHITE  (from Switch Pin 1)  │
  │ Sleeve ◄── BLACK  (from Ground bus)    │
  └──────────────────┘
```

---

### Build Steps

**1. Prepare the Enclosure**
- Drill **Short Side A**: 2x DIN jacks (IN + THRU) — 5/8" (16mm) holes at 18mm and 42mm, centered vertically
- Drill **Long Side**: 4x TRS jacks — 3/8" (9.5mm) holes at 16mm, 38mm, 60mm, 82mm, centered vertically
- Drill **Top Face**: 4x switch slots — ~3mm × 8mm slots at 16mm, 38mm, 60mm, 82mm, centered at 30mm from either long edge
- Use a center punch before every hole to prevent bit wander on the aluminum

**2. Test Switches on Breadboard First**
- The SPDT switches have 2.54mm pin pitch — they fit breadboards
- Use multimeter in continuity mode
- Verify: slide left connects center to pin 1, slide right connects center to pin 2

**3. Wire the Splitter**

Cut wires (~3" each) and solder in this order:

1. **Ground bus** (black wire recommended):
   - DIN Pin 2 → TRS #1 Sleeve → TRS #2 Sleeve → TRS #3 Sleeve → TRS #4 Sleeve

2. **Signal distribution** (use 4 different colors for each output):
   - DIN Pin 5 → Switch #1 Common
   - DIN Pin 5 → Switch #2 Common (parallel)
   - DIN Pin 5 → Switch #3 Common (parallel)
   - DIN Pin 5 → Switch #4 Common (parallel)

3. **Ring outputs** (one color, e.g., red):
   - Switch #1 Pin 1 → TRS #1 Ring
   - Switch #2 Pin 1 → TRS #2 Ring
   - Switch #3 Pin 1 → TRS #3 Ring
   - Switch #4 Pin 1 → TRS #4 Ring

4. **Tip outputs** (another color, e.g., yellow):
   - Switch #1 Pin 2 → TRS #1 Tip
   - Switch #2 Pin 2 → TRS #2 Tip
   - Switch #3 Pin 2 → TRS #3 Tip
   - Switch #4 Pin 2 → TRS #4 Tip

**4. Test Before Closing**
- Connect: CME C2MIDI Pro → MIDI cable → your splitter
- Connect TRS cable from splitter OUT 1 → Chase Bliss Brothers
- Set switch #1 to LEFT (Ring Active)
- Send a MIDI message (Program Change) from Mac/iPhone
- Pedal should respond!
- Repeat for each output

### Testing Commands

From your Pi:

```bash
# Send a test Program Change (preset 1) on channel 1
# This requires amidi (part of alsa-utils)
amidi -p hw:1,0 -S 'C0 00'

# Program Change format: C[channel] [preset]
# C0 = Channel 1, 00 = Preset 0 (first preset)
# C0 01 = Channel 1, Preset 1
# etc.
```

### Pedal Compatibility Quick Reference

| Pedal Brand | Config | Switch Position |
|-------------|--------|-----------------|
| **Chase Bliss** | Ring Active | ◀ LEFT |
| **Strymon** | Tip Active | RIGHT ▶ |
| **Meris** | Tip Active | RIGHT ▶ |
| **Empress** | Tip Active | RIGHT ▶ |
| **Alexander** | Tip Active | RIGHT ▶ |
| **Boss** | Type A (Tip) | RIGHT ▶ |
| **Jackson Audio** | Type A (Tip) | RIGHT ▶ |

### What You Learned

- MIDI electrical protocol (current loop, not voltage)
- TRS MIDI wiring variants (Ring Active vs Tip Active)
- SPDT switch operation (true single-pole, double-throw)
- Basic circuit building and soldering
- Continuity testing with multimeter

### Checkpoint

✅ Enclosure drilled and jacks mounted  
✅ Switches tested on breadboard before soldering  
✅ Wiring complete and tested for continuity  
✅ No shorts between Ring, Tip, and Sleeve  
✅ At least one pedal responds to MIDI from Pi  
✅ Both Chase Bliss pedals work (switches set to LEFT)  

---

## 6. Phase 4: Enclosure & Integration

**Goal:** Put everything in a clean, portable package.

**Time:** 4-8 hours (depends on how fancy you want to get)

### Design Considerations

**All-in-one vs Separate boxes:**
- **All-in-one:** Pi + splitter in same enclosure (cleaner, but harder to build)
- **Separate:** Pi in its own case, splitter in small box (easier, more flexible)

**Recommendation for first build:** Keep them separate. You can always combine later.

### Pi Enclosure Options

1. **Official Pi 5 Case** (~$10) - Simple, clean, good cooling
2. **Argon ONE V3** (~$35) - Premium, silent cooling, all ports accessible
3. **3D Print your own** - If you have access to a printer

### Final Connections

```
┌─────────────────────────────────────────────────────────────────────┐
│                        YOUR STUDIO SETUP                            │
│                                                                     │
│  ┌─────────────┐  USB   ┌─────────────┐  DIN   ┌────────────┐      │
│  │   Pi 5      │───────▶│ CME C2MIDI  │───────▶│ DIY 4-Out  │      │
│  │   in case   │        │   Pro       │        │ Splitter   │      │
│  └─────────────┘        └─────────────┘        └─────┬──────┘      │
│        ▲                                              │             │
│        │ Bluetooth MIDI                          TRS x4            │
│        │                                              │             │
│  ┌─────┴─────┐                                   ┌────┴─────┐      │
│  │  iPhone   │                                   │ Brothers │      │
│  │ CB Presets│                                   │ Mood MK2 │      │
│  └───────────┘                                   │ + 2 more │      │
│                                                  └──────────┘      │
│                                                                     │
│  Power: Pi USB-C (27W) ← Only cable that needs outlet              │
│         CME C2MIDI Pro (powered by Pi USB)                         │
│         Splitter (passive, no power needed)                        │
└─────────────────────────────────────────────────────────────────────┘
```

### Making It "Gig Ready"

For transport:
- Use a small padded pouch or case for Pi + cables
- Velcro the splitter to your pedalboard
- Label your cables (masking tape + sharpie works)

### Software: Auto-Start MIDI Bridge

Create a service that starts automatically when Pi boots:

```bash
# Create service file
sudo nano /etc/systemd/system/midi-bridge.service
```

```ini
[Unit]
Description=MIDI Bridge Service
After=bluetooth.target sound.target

[Service]
Type=simple
User=bfosler
ExecStart=/usr/bin/python3 /home/bfosler/midi_bridge.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start
sudo systemctl enable midi-bridge
sudo systemctl start midi-bridge

# Check status
sudo systemctl status midi-bridge
```

### What You Learned

- Linux systemd services (auto-start programs)
- System design and physical layout
- Cable management and labeling
- "Productizing" a prototype

### Checkpoint

✅ Pi reliably boots and runs MIDI bridge  
✅ All connections are solid and labeled  
✅ Setup is portable and can be reassembled quickly  
✅ Both pedals respond to CB Presets app via Bluetooth  

---

## 7. Phase 5: Footswitches (Future)

**Goal:** Add physical buttons to trigger presets without using your phone.

**Time:** 4-8 hours

### Hardware Needed

| Item | Qty | Price | Notes |
|------|-----|-------|-------|
| Momentary Footswitches (SPST) | 4 | ~$20 | Soft-touch or heavy-duty |
| Enclosure (Hammond 1590BB or larger) | 1 | ~$15 | Room for 4 switches |
| LED indicators (optional) | 4 | ~$5 | Show which preset is active |
| Ribbon cable or wire | 1 | ~$5 | Connect to Pi GPIO |

### GPIO Wiring

```
Pi GPIO Header:
┌──────────────────────────────────────────┐
│  (pin 1) 3.3V    5V (pin 2)              │
│  GPIO 2    ●──●  5V                      │
│  GPIO 3    ●──●  GND ◄── Common          │
│  GPIO 4    ●◄─┼─ Switch 1                │
│  GND       ●──●  GPIO 14                 │
│  GPIO 17   ●◄─┼─ Switch 2                │
│  GPIO 27   ●◄─┼─ Switch 3                │
│  GPIO 22   ●◄─┼─ Switch 4                │
│  ...                                     │
└──────────────────────────────────────────┘

Each switch connects GPIO to GND when pressed.
Use internal pull-up resistors (configured in software).
```

### Python Code for Footswitches

```python
#!/usr/bin/env python3
"""
MIDI Footswitch Controller
Sends Program Change messages when buttons are pressed
"""
import RPi.GPIO as GPIO
import mido
import time

# GPIO pins for each footswitch
SWITCHES = {
    4: 0,   # GPIO 4 → Preset 0
    17: 1,  # GPIO 17 → Preset 1
    27: 2,  # GPIO 27 → Preset 2
    22: 3,  # GPIO 22 → Preset 3
}

# Setup GPIO
GPIO.setmode(GPIO.BCM)
for pin in SWITCHES:
    GPIO.setup(pin, GPIO.IN, pull_up_down=GPIO.PUD_UP)

# Open MIDI output
outport = mido.open_output()  # Opens first available

def send_preset(preset_number):
    """Send Program Change message"""
    msg = mido.Message('program_change', program=preset_number, channel=0)
    outport.send(msg)
    print(f"Sent preset {preset_number}")

# Main loop with debouncing
last_press = {pin: 0 for pin in SWITCHES}
DEBOUNCE_TIME = 0.2  # 200ms

try:
    print("Footswitch controller running. Press Ctrl+C to exit.")
    while True:
        for pin, preset in SWITCHES.items():
            if GPIO.input(pin) == GPIO.LOW:  # Button pressed
                now = time.time()
                if now - last_press[pin] > DEBOUNCE_TIME:
                    send_preset(preset)
                    last_press[pin] = now
        time.sleep(0.01)  # Small delay to reduce CPU usage

except KeyboardInterrupt:
    GPIO.cleanup()
    print("\nExiting...")
```

### Footswitch Enclosure Layout

```
┌─────────────────────────────────────────┐
│                                         │
│   ┌───┐   ┌───┐   ┌───┐   ┌───┐        │
│   │ 1 │   │ 2 │   │ 3 │   │ 4 │        │  ← Footswitches
│   └───┘   └───┘   └───┘   └───┘        │
│                                         │
│   (●)     (●)     (●)     (●)          │  ← Optional LEDs
│                                         │
│        ┌──────────────────┐             │
│        │ Cable to Pi GPIO │             │  ← Ribbon cable out back
│        └──────────────────┘             │
│                                         │
└─────────────────────────────────────────┘
```

---

## 8. MIDI Reference

### Chase Bliss MIDI Implementation

Both Brothers and Mood MK2 respond to:

| Message | Format | Example | Effect |
|---------|--------|---------|--------|
| Program Change | `C[ch] [preset]` | `C0 02` | Load preset 2 on channel 1 |
| Control Change | `B[ch] [cc] [val]` | `B0 14 64` | Set CC#20 to value 100 |
| Expression | CC #100 | `B0 64 7F` | Full expression (127) |

**MIDI Channel:** Both pedals default to channel 1, but can be changed via their dip switches.

### Common CC Numbers for Chase Bliss

| CC# | Parameter | Notes |
|-----|-----------|-------|
| 1-6 | Knob positions | Varies by pedal |
| 100 | Expression | 0-127 |
| 102 | Tap tempo | Send 127 on each tap |

### Python MIDI Cheat Sheet

```python
import mido

# List ports
print(mido.get_input_names())
print(mido.get_output_names())

# Open ports
inport = mido.open_input('C2MIDI Pro')
outport = mido.open_output('C2MIDI Pro')

# Send messages
outport.send(mido.Message('program_change', program=5, channel=0))
outport.send(mido.Message('control_change', control=100, value=64, channel=0))

# Receive messages
for msg in inport:
    print(msg)
```

---

## 9. Troubleshooting

### Pi Won't Boot
- Check power supply (needs 27W for Pi 5)
- Try re-flashing SD card
- Check SD card is fully inserted

### Can't SSH
- Make sure Pi is on same WiFi network
- Try `ping bryanfoslerpi5.local`
- Check router for Pi's IP address

### No MIDI Devices Found
- Run `aconnect -l` to list devices
- Check USB connection (try different port)
- Try `lsusb` to see if C2MIDI Pro is detected
- Make sure USB-C to USB-A adapter is working

### Pedal Not Responding
- Check MIDI channel (usually channel 1)
- Verify switch position matches pedal type (LEFT for Chase Bliss)
- Test with multimeter for continuity through cable and splitter
- Verify TRS cable is TRS (3 conductors), not TS (2 conductors)

### Only One Output Works
- Check that DIN Pin 5 is connected to ALL switch Common pins
- Check for cold solder joints
- Test each switch independently with multimeter

### Bluetooth Won't Connect
- Run `bluetoothctl` and check `power on`
- Reset Bluetooth: `sudo systemctl restart bluetooth`
- Check iOS Bluetooth settings

---

## Quick Reference Commands

```bash
# SSH into Pi
ssh bfosler@bryanfoslerpi5.local

# Check MIDI devices
aconnect -l

# Monitor MIDI
aseqdump -p 20:0

# Restart Bluetooth
sudo systemctl restart bluetooth

# Check service status
sudo systemctl status midi-bridge

# Send test MIDI (preset 0 on channel 1)
amidi -p hw:1,0 -S 'C0 00'

# View system logs
journalctl -f

# Safe shutdown
sudo shutdown -h now
```

---

## Changelog

| Date | Version | Changes |
|------|---------|---------|
| Feb 2026 | 1.0 | Initial guide created |
| Feb 2026 | 2.0 | Updated to CME C2MIDI Pro, 4-output configurable splitter with true SPDT slide switches |

---

*Built for Bryan's Chase Bliss Brothers + Mood MK2 setup*
*Questions? Keep iterating!* 🎸🎛️

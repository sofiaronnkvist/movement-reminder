
# Movement Reminder

A customizable inactivity–movement reminder watch‑app for Garmin devices built with **Connect IQ SDK** and Monkey C.

## Features

* **Custom reminder interval** – 10 – 120 min (default 30 min)
* **Custom movement duration** to clear reminder – 1 – 15 min (default 3 min)
* **Active time window** – fully user‑selectable (default 07:00 – 22:00)
* Vibration + on‑screen alert when the inactivity threshold is reached inside the active window.
* Efficient background logic using Garmin’s native inactivity timestamp.

## Project Layout

```
MovementReminder/
├── source/
│   ├── Main.mc
│   └── MovementReminderView.mc
├── resources/
│   └── settings/
│       └── settings.json
├── manifest.xml
├── build.sh
└── bin/                # compiled .prg will land here
```

## Prerequisites

* **Garmin Connect IQ SDK** (tested with SDK > 6.2.0)
* Java 8+ (for SDK tools)
* `monkeyc` and `connectiq` CLI in `$PATH`

## Build & Install

```bash
# inside project root
./build.sh fenix6          # build for fenix 6; omit arg to use default
./build.sh fenix6 install  # build + install to a connected device / simulator
```

The script creates `bin/MovementReminder.prg`.  
You can then sideload or distribute through the Connect IQ Store.

---

© 2025 Your Name — Licensed under MIT

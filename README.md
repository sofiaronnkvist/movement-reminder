
# Move Reminder Widget

A Garmin Connect IQ widget that helps you stay active by providing gentle reminders to move throughout your day.

## Overview

Move Reminder is a **widget** (not an app) that runs continuously in the background, monitoring inactivity and providing timely movement reminders. Perfect for desk workers, students, and anyone looking to maintain a more active lifestyle.

## Features

- **Always-on background operation** - No need to manually launch
- **Customizable reminder intervals** (10-120 minutes, default: 30)
- **Configurable active hours** (default: 7 AM - 10 PM)
- **Visual and vibration alerts** when it's time to move
- **Manual dismissal** with select button
- **Automatic dismissal** after movement detection
- **Clean, minimal widget interface**
- **Battery-efficient operation**

## How It Works

1. **Install**: Add to your Garmin widget glances
2. **Background Monitoring**: Runs automatically without user intervention
3. **Normal State**: Displays "Move Reminder" with current time
4. **Alert State**: Shows red "TIME TO MOVE!" message
5. **Dismissal**: Press select button or wait for auto-dismissal after movement
6. **Reset**: Timer restarts and continues monitoring

## Widget Display

- **Normal State**: "Move Reminder" title with current time
- **Alert State**: Red "TIME TO MOVE!" with movement instruction
- **Responsive layout** adapts to different screen sizes

## Configuration

All settings configurable through Connect IQ mobile app:
- **Reminder Interval**: 10-120 minutes (default: 30)
- **Active Hours**: Start/end times (default: 7:00 AM - 10:00 PM)
- **Movement Duration**: 1-15 minutes (default: 3)

## Development

### Building
```bash
monkeyc -f monkey.jungle -o MovementReminder.prg -y ../developer_key
```

### Testing
```bash
monkeydo MovementReminder.prg fr245m
```

## Project Structure

```
MovementReminder/
├── source/
│   ├── Main.mc                    # Main widget logic
│   └── MovementReminderView.mc    # Widget view and delegate
├── resources/
│   ├── drawables/                 # Icons and images
│   ├── strings/                   # Text resources
│   └── settings/                  # Configuration
├── manifest.xml                   # Widget manifest
├── monkey.jungle                  # Build config
└── store-listing.md              # Store submission details
```

## Publishing

Ready for Connect IQ Store submission - see `publishing-checklist.md` for details.

---

© 2025 - Connect IQ Widget

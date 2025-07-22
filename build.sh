
#!/usr/bin/env bash
set -e

# Simple build script for Movement Reminder Connect IQ app
# Usage: ./build.sh

echo "Building Movement Reminder for Forerunner 245 Music..."
monkeyc -f monkey.jungle -o MovementReminder.prg -y ../developer_key

if [ $? -eq 0 ]; then
    echo "✅ Build successful! MovementReminder.prg created."
else
    echo "❌ Build failed!"
    exit 1
fi

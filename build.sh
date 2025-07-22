
#!/usr/bin/env bash
set -e

DEVICE="${1:-fenix6}"
ACTION="${2:-build}"

BIN_DIR="bin"
PRG_NAME="MovementReminder.prg"

mkdir -p "$BIN_DIR"

echo "Building for $DEVICE..."
monkeyc -m manifest.xml -o "$BIN_DIR/$PRG_NAME" -d "$DEVICE" --release

echo "Build complete: $BIN_DIR/$PRG_NAME"

if [ "$ACTION" = "install" ]; then
  echo "Installing to device/simulator..."
  connectiq --install "$BIN_DIR/$PRG_NAME"
fi

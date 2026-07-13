#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/.build/release/Voice Log.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
SCRATCH_DIR="${TMPDIR:-/tmp}/voice-log-swiftpm-release"

swift build -c release --jobs 1 --package-path "$ROOT_DIR" --scratch-path "$SCRATCH_DIR"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
cp "$SCRATCH_DIR/release/VoiceLog" "$MACOS_DIR/VoiceLog"
cp "$ROOT_DIR/Info.plist" "$CONTENTS_DIR/Info.plist"
codesign --force --deep --sign - "$APP_DIR"

echo "$APP_DIR"

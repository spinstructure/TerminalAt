#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="TerminalAt"
BUILD_ROOT="$SCRIPT_DIR/build"
APP_DIR="$BUILD_ROOT/${APP_NAME}.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
BINARY="$MACOS/$APP_NAME"

if ! xcrun --find swiftc >/dev/null 2>&1; then
    echo "Apple's developer command-line tools are required." >&2
    echo "Install them with: xcode-select --install" >&2
    exit 1
fi

if command -v plutil >/dev/null 2>&1; then
    plutil -lint "$SCRIPT_DIR/Info.plist" >/dev/null
fi

rm -rf "$APP_DIR"
mkdir -p "$MACOS" "$RESOURCES"

ARCH="$(uname -m)"
MACOS_TARGET="${TERMINALAT_MACOS_TARGET:-13.0}"

echo "Building $APP_NAME for $ARCH (macOS $MACOS_TARGET+)..."

xcrun swiftc \
    -O \
    -parse-as-library \
    -target "${ARCH}-apple-macos${MACOS_TARGET}" \
    "$SCRIPT_DIR"/Sources/*.swift \
    -o "$BINARY"

cp "$SCRIPT_DIR/Info.plist" "$CONTENTS/Info.plist"

# VERSION is the source of truth for the user-facing version number.
if [[ -f "$SCRIPT_DIR/VERSION" ]]; then
    VERSION="$(tr -d '[:space:]' < "$SCRIPT_DIR/VERSION")"
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$CONTENTS/Info.plist"
fi

chmod +x "$BINARY"

# A local ad-hoc signature is sufficient for this personal utility.
codesign --force --deep --sign - "$APP_DIR" >/dev/null
codesign --verify --deep --strict "$APP_DIR"

echo
echo "Built:"
echo "  $APP_DIR"

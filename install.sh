#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="TerminalAt"
BUILT_APP="$SCRIPT_DIR/build/${APP_NAME}.app"
INSTALL_ROOT="$HOME/Applications"
APP_DIR="$INSTALL_ROOT/${APP_NAME}.app"

echo "Building TerminalAt…"
"$SCRIPT_DIR/build.sh"

mkdir -p "$INSTALL_ROOT"

# Ensure an already-running copy does not survive the update.
osascript -e 'tell application "TerminalAt" to quit' >/dev/null 2>&1 || true
sleep 0.2

rm -rf "$APP_DIR"
cp -R "$BUILT_APP" "$APP_DIR"

# Refresh Launch Services' view of the app if the utility is present.
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [[ -x "$LSREGISTER" ]]; then
    "$LSREGISTER" -f "$APP_DIR" >/dev/null 2>&1 || true
fi

echo
echo "Installed:"
echo "  $APP_DIR"
echo
echo "Opening TerminalAt…"
open "$APP_DIR"

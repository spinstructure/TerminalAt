#!/bin/zsh
set -euo pipefail

APP_DIR="$HOME/Applications/TerminalAt.app"

osascript -e 'tell application "TerminalAt" to quit' >/dev/null 2>&1 || true
rm -rf "$APP_DIR"

echo "Removed $APP_DIR"
echo
echo "TerminalAt's favorites and recent-folder history were left intact."
echo "To remove those preferences too, run:"
echo "  defaults delete com.terminalat.app"

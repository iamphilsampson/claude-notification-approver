#!/bin/bash
# Installer for claude-notification-approver.
# Installs cliclick, copies the scripts to ~/.claude-notification-approver/,
# and prints the BetterTouchTool snippets to paste.
set -e

DEST="$HOME/.claude-notification-approver"
SRC="$(cd "$(dirname "$0")" && pwd)"

echo "==> Installing cliclick (mouse control)…"
if command -v cliclick >/dev/null 2>&1; then
  echo "    cliclick already installed."
elif command -v brew >/dev/null 2>&1; then
  brew install cliclick
else
  echo "    Homebrew not found. Install it from https://brew.sh then run: brew install cliclick"
fi

echo "==> Installing scripts to $DEST"
mkdir -p "$DEST"
cp "$SRC"/approve.applescript "$SRC"/open-chat.applescript "$SRC"/calibrate.applescript "$DEST"/

echo
echo "Done. Next steps:"
echo
echo "1) Grant BetterTouchTool BOTH Accessibility AND Input Monitoring"
echo "   (System Settings → Privacy & Security)."
echo
echo "2) In BetterTouchTool add two global keyboard shortcuts, each running a"
echo "   'Run Apple Script (async in background)' action:"
echo
echo "   Approve (e.g. ⌘F4):"
echo "     run script (POSIX file \"$DEST/approve.applescript\")"
echo
echo "   Open chat (e.g. ⌘⇧F4):"
echo "     run script (POSIX file \"$DEST/open-chat.applescript\")"
echo
echo "3) Set Claude notifications to 'Alerts' (System Settings → Notifications → Claude)."
echo
echo "4) Calibrate: trigger a Claude permission notification, then run and hold your"
echo "   cursor on the 'Allow once' button for ~5s:"
echo "     osascript \"$DEST/calibrate.applescript\""
echo

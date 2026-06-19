# Claude Notification Approver

Approve (or open) Claude Code's macOS permission prompts with a **single keypress** — without switching away from whatever you're working on. Map the hotkey to a USB macro button or foot pedal and you get one-tap approvals.

When Claude Code runs in the background and needs permission, macOS shows a notification with an **"Allow once"** button. This tool clicks that button for you when you press a global hotkey, then puts your cursor back where it was. You never leave your current app.

## Why this exists

Claude Code's desktop app has **no keyboard shortcut and no API to approve a permission prompt** — you have to click the button. If you're working in another app while Claude runs, that means stopping, finding the window, clicking, and going back. A hotkey that "presses Enter" doesn't work either: it goes to whatever app is focused, not to Claude, and even in Claude it would just send a chat message.

The only reliable surface is the **macOS notification banner**. But macOS does not expose the notification's buttons to the accessibility tree, and the button only renders on hover. So this tool:

1. Moves the mouse onto the notification (which reveals the "Allow once" button),
2. Clicks it by **screen coordinate**,
3. Restores your cursor to its original position.

The coordinate is calibrated once per screen and stored in a config file. See [WRITEUP.md](WRITEUP.md) for the full story of how this was reverse-engineered.

## What you get

| Hotkey (suggested) | Script | Action |
|---|---|---|
| ⌘F4 | `approve.applescript` | Clicks **Allow once** on a permission prompt |
| ⌘⇧F4 | `open-chat.applescript` | Clicks the notification **body** → opens that chat (use for the short "waiting for your input" alert that has no button) |

## Requirements

- macOS (tested on macOS 26 / Apple Silicon; works on Intel too)
- A **global-hotkey launcher** to run the scripts on a keypress — free options include [Hammerspoon](https://www.hammerspoon.org/), [skhd](https://github.com/koekeishiya/skhd), or macOS's built-in **Shortcuts** app ([BetterTouchTool](https://folivora.ai/) also works). See [Bind the hotkeys](#bind-the-hotkeys).
- [`cliclick`](https://github.com/BlueM/cliclick) — moves/clicks the mouse (`brew install cliclick`)
- The Claude desktop app, with **notification style set to "Alerts"** (System Settings → Notifications → Claude). Alerts stay on screen and expose the button; Banners auto-dismiss and hide it.

## Install

```bash
git clone https://github.com/iamphilsampson/claude-notification-approver.git
cd claude-notification-approver
./install.sh
```

`install.sh` installs `cliclick`, copies the scripts to `~/.claude-notification-approver/`, and prints the exact BetterTouchTool snippets to paste.

### Bind the hotkeys

Any global-hotkey launcher can run the scripts — pick one below. **Whichever you choose, grant it Accessibility** (System Settings → Privacy & Security → Accessibility); macOS requires this to post the click. Ready-made configs live in [`hotkeys/`](hotkeys/).

> Avoid bare function keys (F4 etc.) as triggers — macOS may intercept them as hardware media keys. A modifier combo (⌘F4, ⌃⌥⌘A, …) is safest.

#### Karabiner-Elements — free, fastest (Command-key gestures)

No reach, no letters — fire on the Command keys themselves (great on a laptop/trackpad):
- **Both ⌘ together → approve** (deliberate two-thumb squeeze — can't misfire)
- **Right ⌘ tapped alone → open chat** (your normal ⌘ shortcuts keep working)

```sh
brew install --cask karabiner-elements
cp hotkeys/karabiner-claude.json ~/.config/karabiner/assets/complex_modifications/
```
Then **Karabiner → Complex Modifications → Add rule** and enable both. Grant Karabiner its permissions on first launch.

#### Hammerspoon — free, recommended

Add to `~/.hammerspoon/init.lua`, then reload Hammerspoon:

```lua
hs.hotkey.bind({"cmd"}, "f4", function() hs.execute("osascript $HOME/.claude-notification-approver/approve.applescript", true) end)
hs.hotkey.bind({"cmd", "shift"}, "f4", function() hs.execute("osascript $HOME/.claude-notification-approver/open-chat.applescript", true) end)
```

#### skhd — free, CLI

`brew install skhd && skhd --start-service`, then add to `~/.skhdrc`:

```
cmd - f4         : osascript $HOME/.claude-notification-approver/approve.applescript
cmd + shift - f4 : osascript $HOME/.claude-notification-approver/open-chat.applescript
```

#### macOS Shortcuts — built-in, no install

1. Open **Shortcuts** → new shortcut → add a **Run Shell Script** action:
   `osascript $HOME/.claude-notification-approver/approve.applescript`
2. In the shortcut's details (ⓘ panel), assign a **keyboard shortcut** (e.g. ⌘F4).
3. Repeat with a second shortcut for `open-chat.applescript`.
4. Grant **Shortcuts** Accessibility when first prompted.

#### BetterTouchTool — paid

Two keyboard triggers, each a **"Run Apple Script (async in background)"** action:

```applescript
run script (POSIX file "/Users/YOURNAME/.claude-notification-approver/approve.applescript")
```
(and a second pointing at `open-chat.applescript`). Grant BTT **Accessibility** and **Input Monitoring**.

### Calibrate

The "Allow once" button position differs per display, so calibrate once per screen:

1. Trigger a Claude permission notification (and switch away from Claude so the notification appears).
2. Run the calibrator and **hold your cursor on the "Allow once" button** for ~5 seconds:
   ```bash
   osascript ~/.claude-notification-approver/calibrate.applescript
   ```
3. It saves `WIDTH:X:Y` to `~/.claude-notification-approver/button-config.txt`.

Repeat on each display you use. The approver auto-selects the right coordinate by detecting the current screen width.

## How config works

Plain text, one line per screen width, in `~/.claude-notification-approver/`:

- `button-config.txt` — approve-button coordinate(s): `1440:1388:132`
- `open-config.txt` — (optional) body click point for open-chat; defaults work on most screens

## Caveats

- **The notification must actually appear** — Claude only raises an OS notification when you're *not* viewing that session. That's the intended use (approving while in another app), but the hotkey does nothing if Claude is focused.
- **Per-screen calibration.** Switch displays → calibrate that screen once.
- **Coordinate-based**, because macOS won't expose the button to automation. If the Claude app changes its notification layout, you may need to re-calibrate.

## License

MIT — see [LICENSE](LICENSE).

---

Inspired by the USB-button-to-approve-Claude setups making the rounds, built for people who'd rather use a keyboard shortcut (or a cheap macro key) in the meantime.

# How this was built (and why it's weirder than it should be)

This started from a simple wish: I saw someone pair a USB button with Claude Code to approve responses with a single tap, and I wanted the same - or at least a keyboard shortcut in the meantime. What looked like a five-minute job turned into a proper little reverse-engineering exercise, because macOS fights you at every layer. Here's the journey, in case it saves someone else the afternoon.

## The naive idea, and why it fails

"Just bind a key to press Enter when the prompt shows." Two problems:

1. **A global hotkey goes to the focused app.** The whole point is that I'm working in Slack or a browser while Claude runs in the background. A key that sends Enter sends it to Slack, not Claude.
2. **Even with Claude focused, Enter is wrong.** If the cursor is in the chat box, Enter sends a message. There's no key that means "approve this permission."

I checked: the Claude desktop app has **no keyboard shortcut to approve a permission prompt, no clickable-notification API, and no background-approval mechanism.** You can reduce how often you're asked (permission modes, allowlists), but to actually approve, a human has to click the button.

## The only surface that works: the notification

When Claude needs permission and you're not looking at the session, macOS raises a notification banner with an **"Allow once"** button. That button is the target. So the plan became: detect the notification, click its button, without stealing focus or moving my work.

### Dead end 1: the accessibility tree

The clean way to click a UI element is via the accessibility (AX) API - `System Events` can read and click buttons in other apps. So I pointed it at the `NotificationCenter` process and dumped its windows.

- First hurdle: **Accessibility permission.** Reading another app's UI needs it, and unlike Automation, macOS doesn't even prompt - it just denies (`error -25211`). The script has to run from an app that *has* Accessibility. BetterTouchTool does, so BTT became the executor.
- Real hurdle: **the button isn't in the tree.** `NotificationCenter` exposes a single full-screen container window. Dumping its entire contents returned, at most, a stray static-text element - and crucially, **zero buttons**, even while the "Allow once" button was plainly visible on screen.

So AX was out. macOS renders the notification's buttons in a way that the accessibility tree doesn't expose.

### Dead end 2: hover, then read

Watching closely revealed the next quirk: **the button only appears when you hover the notification.** Un-hovered, it's just text. I built a version that moved the mouse onto the banner first, then re-scanned the AX tree - but the button still wasn't there. Visible to the eye, invisible to automation.

### What actually worked: click by coordinate

If we can't *find* the button programmatically, we can still *click where it is*. The notification is anchored to the top-right of the screen, so the button sits at a stable screen coordinate. The approach:

1. Record the current mouse position.
2. Move the mouse to the button's coordinate. This both **reveals** the button (hover) and **lands on it**.
3. Click.
4. Move the mouse back.

For the click I used [`cliclick`](https://github.com/BlueM/cliclick), since AppleScript can't move the mouse natively and the system Python lacks Quartz.

### Finding the coordinate

I needed the exact button location. Rather than guess from screenshots, I wrote a tiny calibrator: it samples the mouse position every 0.6s for ~5 seconds while you hold the cursor on the button. On a 1440-wide display the button centre came back as a rock-solid `1388,132` across all nine samples. That coordinate gets saved per screen width, so the tool adapts when you move to a different display - just recalibrate once.

## The bugs along the way

- **F-keys are a trap.** My first hotkey was F6, then ⌘F4 - and nothing fired. macOS was eating the function key as a hardware media key before BTT saw it. (It also didn't help that BTT was switched off entirely at one point. 🙃) A plain modifier combo, or making sure BTT is enabled and has Input Monitoring, fixes it.
- **`by` is a reserved word in AppleScript.** Naming a variable `by` (as in `repeat ... by 2`) is a silent syntax error - the script just won't compile, so the hotkey does nothing with no obvious clue. Renamed to `clickY`.
- **Notifications only fire when unfocused.** The OS notification appears only when you're *not* viewing the Claude session. Obvious in hindsight, confusing while testing (you keep staring at Claude waiting for a banner that will never come while you're looking at it).

## Two notification types

There are two flavours:

- **Permission prompt** (tall): has the "Allow once" button → `approve.applescript` clicks it.
- **"Waiting for your input"** (short): no button, just text → `open-chat.applescript` clicks the body, which opens that chat.

They live at different heights and macOS won't tell us which is showing, so they get **separate hotkeys** rather than one clever auto-detecting key. That's not a compromise so much as a feature: on a physical macro pad, Approve and Open are naturally different buttons.

## Takeaway

The "right" way (accessibility API) is a dead end because macOS doesn't expose notification buttons. The pragmatic way - hover to reveal, click by calibrated coordinate, restore the cursor - is a bit crude but completely reliable. Sometimes the robust solution is the unglamorous one.

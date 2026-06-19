-- Hammerspoon hotkeys for claude-notification-approver
-- Append this to ~/.hammerspoon/init.lua, then reload Hammerspoon
-- (menu bar → Reload Config). Grant Hammerspoon Accessibility permission.
--
-- ⌘F4        → approve  (clicks "Allow once")
-- ⌘⇧F4       → open chat (clicks the notification body)

hs.hotkey.bind({ "cmd" }, "f4", function()
	hs.execute("osascript $HOME/.claude-notification-approver/approve.applescript", true)
end)

hs.hotkey.bind({ "cmd", "shift" }, "f4", function()
	hs.execute("osascript $HOME/.claude-notification-approver/open-chat.applescript", true)
end)

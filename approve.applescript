-- approve.applescript — click "Allow once" on Claude's macOS permission notification
--
-- macOS does NOT expose the notification's button to the accessibility tree, so we
-- click it by SCREEN COORDINATE. The button is revealed only on hover, so we move
-- the mouse onto it first. Coordinates are stored per screen width in
-- ~/.claude-notification-approver/button-config.txt so the tool works across displays.
--
-- Flow: record mouse -> hover button (reveals it) -> click -> restore mouse.
-- Wire this to a global hotkey in BetterTouchTool (which must have Accessibility).

property defaultRightOffset : 52 -- fallback: px from the right screen edge to button centre
property defaultY : 132 -- fallback: px from the top to button centre

on cliclickPath()
	set p1 to "/opt/homebrew/bin/cliclick"
	try
		do shell script "test -x " & quoted form of p1
		return p1
	end try
	return "/usr/local/bin/cliclick"
end cliclickPath

on configPath()
	return (POSIX path of (path to home folder)) & ".claude-notification-approver/button-config.txt"
end configPath

-- read config lines "WIDTH:X:Y" -> {x,y} for this width, or {}
on lookupConfig(scrW)
	try
		set txt to (read (POSIX file (my configPath())) as «class utf8»)
		repeat with ln in (paragraphs of txt)
			set ln to ln as text
			if ln contains ":" then
				set oldTID to AppleScript's text item delimiters
				set AppleScript's text item delimiters to ":"
				set parts to text items of ln
				set AppleScript's text item delimiters to oldTID
				if (count of parts) ≥ 3 then
					if ((item 1 of parts) as integer) is scrW then
						return {(item 2 of parts) as integer, (item 3 of parts) as integer}
					end if
				end if
			end if
		end repeat
	end try
	return {}
end lookupConfig

on run
	set cc to my cliclickPath()
	set origPos to ""
	try
		set origPos to (do shell script cc & " p:.")
	end try

	-- screen width (the NotificationCenter container spans the main display)
	set scrW to 1440
	try
		tell application "System Events" to tell process "NotificationCenter" to set scrW to (item 1 of (size of window 1))
	end try

	set coords to my lookupConfig(scrW)
	if coords is {} then
		set clickX to (scrW - defaultRightOffset) as integer
		set clickY to defaultY
	else
		set clickX to (item 1 of coords)
		set clickY to (item 2 of coords)
	end if

	-- hover to reveal the button, click it, restore the mouse
	try
		do shell script cc & " m:" & clickX & "," & clickY
	end try
	delay 0.45
	try
		do shell script cc & " c:" & clickX & "," & clickY
	end try
	delay 0.1
	if origPos is not "" then
		try
			do shell script cc & " m:" & origPos
		end try
	end if
	return "approved"
end run

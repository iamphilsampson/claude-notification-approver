-- open-chat.applescript — click the BODY of Claude's notification to open that chat
--
-- For the short "Claude is waiting for your input" alert that has no button, and for
-- jumping to any notification's session. Clicking the body needs no hover.
-- Body click point is stored per screen width in
-- ~/.claude-notification-approver/open-config.txt; falls back to a left-of-centre
-- point near the top where the icon/title sits.
--
-- Flow: record mouse -> click notification body -> restore mouse.
-- Wire this to a second global hotkey in BetterTouchTool.

property defaultLeftOffset : 300 -- fallback: px from the right screen edge to body click point
property defaultY : 70 -- fallback: px from the top to body click point

on cliclickPath()
	set p1 to "/opt/homebrew/bin/cliclick"
	try
		do shell script "test -x " & quoted form of p1
		return p1
	end try
	return "/usr/local/bin/cliclick"
end cliclickPath

on configPath()
	return (POSIX path of (path to home folder)) & ".claude-notification-approver/open-config.txt"
end configPath

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

	set scrW to 1440
	try
		tell application "System Events" to tell process "NotificationCenter" to set scrW to (item 1 of (size of window 1))
	end try

	set coords to my lookupConfig(scrW)
	if coords is {} then
		set clickX to (scrW - defaultLeftOffset) as integer
		set clickY to defaultY
	else
		set clickX to (item 1 of coords)
		set clickY to (item 2 of coords)
	end if

	try
		do shell script cc & " c:" & clickX & "," & clickY
	end try
	delay 0.1
	if origPos is not "" then
		try
			do shell script cc & " m:" & origPos
		end try
	end if
	return "opened"
end run

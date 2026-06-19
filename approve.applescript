-- approve.applescript - click "Allow once" on Claude's macOS permission notification
--
-- macOS exposes NOTHING about the notification to the accessibility tree (no button,
-- no frame), so we click by SCREEN COORDINATE after hovering to reveal the button.
-- The button sits near the bottom of the banner, so its height varies: a 3-line alert
-- puts it lower than a 2-line one. We can't detect which is showing, so:
--   - First press         -> click the TALL position.
--   - Quick re-press (<=3s) -> alternate to the SHORT position.
-- So tall alerts approve in one press; short alerts in two. Misses land in empty
-- space below the banner, so they're harmless.
--
-- Coordinates per screen width live in ~/.claude-notification-approver/button-config.txt
-- as  WIDTH:X:Y_TALL:Y_SHORT  (Y_SHORT optional; calibrate with calibrate.applescript).

property defaultRightOffset : 52
property defaultYTall : 132
property defaultYShort : 112
property retryWindow : 3 -- seconds; a re-press within this counts as a retry

on cliclickPath()
	set p1 to "/opt/homebrew/bin/cliclick"
	try
		do shell script "test -x " & quoted form of p1
		return p1
	end try
	return "/usr/local/bin/cliclick"
end cliclickPath

on cfgDir()
	return (POSIX path of (path to home folder)) & ".claude-notification-approver/"
end cfgDir

-- returns {x, yTall, yShort} for this width, or {} if not configured
on lookupConfig(scrW)
	try
		set txt to (read (POSIX file (my cfgDir() & "button-config.txt")) as «class utf8»)
		repeat with ln in (paragraphs of txt)
			set ln to ln as text
			if ln contains ":" then
				set oldTID to AppleScript's text item delimiters
				set AppleScript's text item delimiters to ":"
				set parts to text items of ln
				set AppleScript's text item delimiters to oldTID
				if (count of parts) ≥ 3 then
					if ((item 1 of parts) as integer) is scrW then
						set xx to (item 2 of parts) as integer
						set yt to (item 3 of parts) as integer
						if (count of parts) ≥ 4 then
							set ys to (item 4 of parts) as integer
						else
							set ys to yt - 20
						end if
						return {xx, yt, ys}
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
		set clickX to (scrW - defaultRightOffset) as integer
		set yTall to defaultYTall
		set yShort to defaultYShort
	else
		set clickX to (item 1 of coords)
		set yTall to (item 2 of coords)
		set yShort to (item 3 of coords)
	end if

	-- decide tall vs short from retry timing
	set statePath to my cfgDir() & "approve-state.txt"
	set nowT to (do shell script "date +%s") as integer
	set lastT to 0
	set lastPos to "short"
	try
		set st to (read (POSIX file statePath) as «class utf8»)
		set oldTID to AppleScript's text item delimiters
		set AppleScript's text item delimiters to ":"
		set sp to text items of st
		set AppleScript's text item delimiters to oldTID
		set lastT to (item 1 of sp) as integer
		set lastPos to (item 2 of sp) as text
	end try

	if (nowT - lastT) > retryWindow then
		set usePos to "tall"
	else if lastPos is "tall" then
		set usePos to "short"
	else
		set usePos to "tall"
	end if

	if usePos is "tall" then
		set clickY to yTall
	else
		set clickY to yShort
	end if

	-- save state
	try
		set f to open for access (POSIX file statePath) with write permission
		set eof f to 0
		write ((nowT as text) & ":" & usePos) to f as «class utf8»
		close access f
	on error
		try
			close access (POSIX file statePath)
		end try
	end try

	-- hover to reveal the button, click, restore the mouse
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
	return "approved (" & usePos & " @ " & clickX & "," & clickY & ")"
end run

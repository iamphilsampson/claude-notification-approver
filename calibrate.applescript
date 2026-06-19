-- calibrate.applescript — record the "Allow once" button's screen coordinate
--
-- Run this, then HOLD your mouse over the "Allow once" button for ~5 seconds.
-- It saves the coordinate to ~/.claude-notification-approver/button-config.txt,
-- keyed by the current screen width, so approve.applescript uses it automatically.
--
-- Calibrate a new display by switching to it, triggering a Claude permission
-- notification, running this, and holding the cursor on "Allow once".
--
-- (To calibrate the open-chat body point instead, change the two occurrences of
--  "button-config.txt" below to "open-config.txt".)

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

on writeFile(thePath, theText)
	try
		set f to open for access (POSIX file thePath) with write permission
		set eof f to 0
		write theText to f as «class utf8»
		close access f
	on error
		try
			close access (POSIX file thePath)
		end try
	end try
end writeFile

on readFile(thePath)
	try
		return (read (POSIX file thePath) as «class utf8»)
	on error
		return ""
	end try
end readFile

on run
	set cc to my cliclickPath()

	-- sample the mouse 9 times over ~5s while held on the button
	set samples to {}
	repeat 9 times
		try
			set end of samples to (do shell script cc & " p:.")
		end try
		delay 0.6
	end repeat

	-- pick the most frequently seen position (the held spot)
	set bestPos to (item (count of samples) of samples)
	set bestCount to 0
	repeat with s in samples
		set c to 0
		repeat with t in samples
			if (t as text) is (s as text) then set c to c + 1
		end repeat
		if c > bestCount then
			set bestCount to c
			set bestPos to (s as text)
		end if
	end repeat

	set oldTID to AppleScript's text item delimiters
	set AppleScript's text item delimiters to ","
	set xy to text items of bestPos
	set AppleScript's text item delimiters to oldTID
	set bx to (item 1 of xy) as integer
	set clickY to (item 2 of xy) as integer

	-- current screen width
	set scrW to 1440
	try
		tell application "System Events" to tell process "NotificationCenter" to set scrW to (item 1 of (size of window 1))
	end try

	-- upsert the line for this width
	set existing to my readFile(my configPath())
	set newLines to {}
	repeat with ln in (paragraphs of existing)
		set ln to ln as text
		if ln is not "" and ln contains ":" then
			set t2 to AppleScript's text item delimiters
			set AppleScript's text item delimiters to ":"
			set p to text items of ln
			set AppleScript's text item delimiters to t2
			if (count of p) ≥ 1 then
				if ((item 1 of p) as integer) is not scrW then set end of newLines to ln
			end if
		end if
	end repeat
	set end of newLines to ((scrW as text) & ":" & (bx as text) & ":" & (clickY as text))

	set t3 to AppleScript's text item delimiters
	set AppleScript's text item delimiters to (return)
	set outText to (newLines as text)
	set AppleScript's text item delimiters to t3
	my writeFile(my configPath(), outText)

	return "Calibrated width " & scrW & " -> " & bx & "," & clickY & " (" & bestCount & "/9 samples)"
end run

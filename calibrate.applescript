-- calibrate.applescript - record the "Allow once" button coordinate for this screen.
--
-- Run it, HOLD your cursor on the "Allow once" button for ~5s, then pick whether
-- this was a TALL (3-line) or SHORT (2-line) alert. Saves to
-- ~/.claude-notification-approver/button-config.txt as WIDTH:X:Y_TALL:Y_SHORT.
-- Calibrate each height once (and each display you use).

property cc : "/opt/homebrew/bin/cliclick"

on cfgPath()
	return (POSIX path of (path to home folder)) & ".claude-notification-approver/button-config.txt"
end cfgPath

on readFile(p)
	try
		return (read (POSIX file p) as «class utf8»)
	on error
		return ""
	end try
end readFile

on writeFile(p, t)
	try
		set f to open for access (POSIX file p) with write permission
		set eof f to 0
		write t to f as «class utf8»
		close access f
	on error
		try
			close access (POSIX file p)
		end try
	end try
end writeFile

on run
	-- sample the held cursor position
	set samples to {}
	repeat 9 times
		try
			set end of samples to (do shell script cc & " p:.")
		end try
		delay 0.6
	end repeat
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

	-- screen width
	set scrW to 1440
	try
		tell application "System Events" to tell process "NotificationCenter" to set scrW to (item 1 of (size of window 1))
	end try

	-- which height?
	set choice to button returned of (display dialog "Button captured at " & bx & "," & clickY & " on a " & scrW & "px-wide screen." & return & return & "Which alert was showing?" buttons {"Cancel", "Short (2-line)", "Tall (3-line)"} default button "Tall (3-line)")
	if choice is "Cancel" then return "cancelled"

	-- load existing slots for this width (preserve the one we're not calibrating)
	set yTall to clickY + 20
	set yShort to clickY - 20
	set existing to my readFile(my cfgPath())
	set newLines to {}
	repeat with ln in (paragraphs of existing)
		set ln to ln as text
		if ln is not "" and ln contains ":" then
			set t2 to AppleScript's text item delimiters
			set AppleScript's text item delimiters to ":"
			set p to text items of ln
			set AppleScript's text item delimiters to t2
			if ((item 1 of p) as integer) is scrW then
				if (count of p) ≥ 3 then set yTall to (item 3 of p) as integer
				if (count of p) ≥ 4 then set yShort to (item 4 of p) as integer
			else
				set end of newLines to ln
			end if
		end if
	end repeat

	if choice starts with "Tall" then
		set yTall to clickY
	else
		set yShort to clickY
	end if

	set end of newLines to ((scrW as text) & ":" & (bx as text) & ":" & (yTall as text) & ":" & (yShort as text))

	set t3 to AppleScript's text item delimiters
	set AppleScript's text item delimiters to (return)
	set outText to (newLines as text)
	set AppleScript's text item delimiters to t3
	my writeFile(my cfgPath(), outText)

	return choice & " calibrated: " & scrW & " -> " & bx & "," & clickY
end run

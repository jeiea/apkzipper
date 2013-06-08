package require registry
set a [registry keys {HKEY_LOCAL_MACHINE\softw}]
puts $a


lassign [chan pipe] p1r p1w
lassign [chan pipe] p2r p2w

proc got_stdout {chan args} {
	set line [read $chan 128]
	puts -nonewline $line
}

proc got_stderr {chan args} {
	#gets $chan line
	set line [read $chan 10]
	puts -nonewline $line
}

fileevent $p1r readable "got_stdout $p1r"
#fileevent $p2r readable "got_stderr $p2r"

set args "music.mp3"

set pids [exec mplayer $args >@ $p1w 2>@ $p2w &]
puts $pids

proc kill {args} {
	foreach ch $args {
		catch {puts $ch "q"}
		catch {set junk [read $ch]}
		catch {close $ch}
	}
}

vwait forever
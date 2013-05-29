# kostix's snippet from tcler bin
proc scan_dir {dirname pattern} {
    set out [list]
    foreach d [glob -type d -nocomplain -dir $dirname *] {
        set out [concat $out [scan_dir $d $pattern]]
    }
    concat $out [glob -type f -nocomplain -dir $dirname $pattern]
}

proc bgopen_handler {callback chan} {
	{*}$callback [read $chan]
	if {[eof $chan]} {
		fconfigure $chan -blocking true
		set ::bgAlive($chan) [catch {close $chan} {} erropt]
		if $::bgAlive($chan) {{*}$callback "\n[mc ERROR] $::bgAlive($chan): [dict get $erropt -errorinfo]\n"}
	}
}

proc bgopen {callback args} {
	set chan [open "| $args 2>@1" r]
	fconfigure $chan -blocking false
	fileevent $chan readable [list bgopen_handler $callback $chan]
	vwait ::bgAlive($chan)
	set ret $::bgAlive($chan)
	unset ::bgAlive($chan)
	return $ret
}

proc seq args {
	set res {}
	switch [llength $args] {
	1 {
		for {set i 0} {$i < $args} {incr i} {lappend res $i}
		return $res
	}
	2 {
		lassign $args start end
		if {$start < $end} {
			set step 1
			set cond {$i < $end}
		} {
			set step -1
			set cond {$i > $end}
		}
		for {set i $start} $cond {incr i $step} {lappend res $i}
		return $res
	}
	3 {
		lassign $args start end step
		if {$step > 0} {
			set cond {$i < $end}
		} {
			set cond {$i > $end}
		}
		for {set i $start} $cond {incr i $step} {lappend res $i}
		return $res
	}
	}
}

#wm iconify .
#console show
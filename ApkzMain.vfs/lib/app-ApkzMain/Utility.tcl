# �������� �ڵ��� mcExtract�� �ִ�.
# ���߿� �׽�Ʈ�ڵ尡 �߰��Ǹ� �ӽ÷� ���⿡ �־ �� �� ����.


# kostix's snippet from tcler bin
proc scan_dir {dirname pattern} {
	set out [list]
	foreach d [glob -type d -nocomplain -dir $dirname *] {
		set out [concat $out [scan_dir $d $pattern]]
	}
	concat $out [glob -type f -nocomplain -dir $dirname {*}$pattern]
}


proc bgopen_handler {callback chan} {
	append ::bgData($chan) [set data [read $chan]]
	catch {{*}$callback $data}
	
	if {[eof $chan]} {
		fconfigure $chan -blocking true
		set returnInfo ""
		set isErr [catch {close $chan} errmsg returnInfo]
		# errorinfo�� errmsg�� ����Ʈ���̽��� �� ���� ���̴�.
		# ���⼱ ������ ��Ƶα⸸ �ϰ�, bgopen���� error�� ȣ���Ѵ�.
		dict set returnInfo -errormsg $errmsg
		dict set returnInfo -stdout $::bgData($chan)
		unset ::bgData($chan)
		set ::bgAlive($chan) $returnInfo
	}
}

if {$tcl_platform(platform) == {windows}} {
	
	
	proc bgopen_receive {callback chan} {
		append ::bgData($chan) [set data [chan read $chan]]
		catch {{*}$callback $data}
	}
	
	proc bgopen_cleanup {callback chan} {
		bgopen_receive $callback $chan
		chan configure $chan -blocking true
		chan close $chan
		set output $::bgData($chan)
		unset ::bgData($chan)
		return $output
	}
	
	proc whenClose {hProc outw errw inw inr callback} {
		set exitcode [twapi::get_process_exit_code $hProc]
		twapi::close_handle $hProc
		
		foreach chan [list $outw $errw $inw $inr] {
			chan close $chan
		}
		set stdoutData [bgopen_cleanup $callback $outr]
		set stderrData [bgopen_cleanup $callback $errr]
		
		set ret [concat $stdoutData $stderrData]
		if {$exitcode != 0} {
			error $stdoutData $stderrData $exitcode
		}
		return $ret
	}
	
	proc _bgopen {callback args} {
		lassign [chan pipe] inr inw
		lassign [chan pipe] outr outw
		lassign [chan pipe] errr errw
		chan configure $outr -blocking false -buffering none
		chan configure $errr -blocking false -buffering none
		set pid [eval exec $args >@ $outw 2>@ $errw &]
		puts "start: $args"
		
		set handleOut [list bgopen_receive $callback $outr]
		set handleErr [list bgopen_receive $callback $errr]
		chan event $outr readable $handleOut
		chan event $errr readable $handleErr
		
		set hProc [twapi::get_process_handle $pid -access generic_execute]
		twapi::wait_on_handle $hProc -executeonce 1 -async [list set ::bgWait$pid 0]\;#
		vwait ::bgWait$pid
		unset ::bgWait$pid

#		while {[twapi::process_exists $pid]} {
#			after 20
#			update
#		}

#		set ::mutex($pid) [thread::mutex create -recursive]
#		thread::mutex lock $::mutex($pid)
#		twapi::wait_on_handle $hProc -async [list puts di]\;[list thread::mutex unlock ::mutex($pid)]\;#
#		thread::mutex lock $::mutex($pid)
#		thread::mutex unlock $::mutex($pid)
#		thread::mutex destroy $::mutex($pid)
#		unset ::mutex($pid)
		set exitcode [twapi::get_process_exit_code $hProc]
		twapi::close_handle $hProc
		
		foreach chan [list $outw $errw $inw $inr] {
			chan close $chan
		}
		set stdoutData [bgopen_cleanup $callback $outr]
		set stderrData [bgopen_cleanup $callback $errr]
		
		set ret [concat $stdoutData $stderrData]
		if {$exitcode != 0} {
			error $stdoutData $stderrData $exitcode
		}
		return $ret
	}
	

proc bgopen {callback args} {
	set chan [open "| $args 2>@1" r]
	fconfigure $chan -blocking false
	fileevent $chan readable [list bgopen_handler $callback $chan]
	set ::bgAlive($chan) {}
	vwait ::bgAlive($chan)

	set ret $::bgAlive($chan)
	unset ::bgAlive($chan)
	if {[dict get $ret -code] == 1} {
		# errmsg�� ���ݱ��� ���α׷��� ����� ������(stdout)�� ������.
		error [dict get $ret -stdout] [dict get $ret -errorinfo] [dict get $ret -errorcode]
	}
	return [dict get $ret -stdout]
}
}

bind MAINWIN <Destroy> {+
	foreach bgproc {[array names ::bgAlive]} {
		close $bgproc
		tk_messageBox -title "close $bgproc"
	}
}

# ���̽��� range�� ����. �������� seq�� �������� �𸣰�����.
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

proc AdaptPath file {file nativename [file normalize $file]}

package require http
proc httpcopy {url {file ""}} {
	set url [string map {https:// http://} $url]
	set token [::http::geturl $url -progress httpCopyProgress]

	#���������� '�迭'�̶� upvaró���� �ؾ��Ѵ�.
	upvar #0 $token state
	if ![info exist state] {error 1}

	# HTTP �����̷��� ó��.
	# 1. ����� �̿��� ���. dict�� ��ҹ��� ������ ����� �� ��.
	foreach {name value} $state(meta) {
		if {[regexp -nocase ^location$ $name]} {
			return [httpcopy [string trim $value] $file]
		}
	}
	
	set data [::http::data $token]
	if {$file != {}} {
		set out [open $file wb]
		fconfigure $out -encoding binary -translation binary
		puts -nonewline $out $data
		close $out
	}
	::http::cleanup $token
	return $data
}

proc httpCopyProgress {token total current} {
	if $total {
		if ![winfo exist .t] {
			pack [ttk::progressbar [toplevel .t].pb -length 300]
			wm title .t [mc {Downloading...}]
			bind .t <Destroy> [list ::http::cleanup $token]
		}
		.t.pb config -value [expr $current  * 100 / $total]
	}
	if {$total == $current} {
		bind .t <Destroy> {}
		destroy .t
	}
}

proc max {args} {
	if ![llength $args] return
	set ret [lindex $args 0]
	foreach item $args {
		if {$ret < $item} {
			set ret $item
		}
	}
	return $ret
}

proc min {args} {
	if ![llength $args] return
	set ret [lindex $args 0]
	foreach item $args {
		if {$ret > $item} {
			set ret $item
		}
	}
	return $ret
}

proc getChildsRecursive {win} {
	set ret {}
	foreach child [winfo children $win] {
		lappend ret $child
		set ret [concat $ret [allChildsWidget $child]]
	}
	return $ret
}

proc InputDlg {msg} {
	set id [string map {. {}} [expr rand()]]
	set focusing {
		raise .pul
		focus .pul.entry
	}

	if [winfo exist .pul] {
		eval $focusing
		return {}
	} {
		toplevel .pul
	}
	wm title .pul [mc {Input}]

	pack [ttk::label .pul.label -text $msg] -side top
	pack [ttk::combobox .pul.entry -values [lrange $::hist($msg) 1 end]] -side bottom -fill x
	.pul.entry insert 0 [lindex $::hist($msg) 0]
	.pul.entry selection range 0 end
	foreach widget {.pul .pul.label .pul.entry} {
		bind $widget <Escape> {
			destroy .pul
		}
	}
	bind .pul.entry <Return> {
		set ::dlginputval [.pul.entry get]
	}
	
	bind .pul <Destroy> {
		set ::dlginputval {}
	}
	
	eval $focusing
	vwait ::dlginputval
	
	set ret $::dlginputval
	destroy .pul
	return $ret
}

# �����ڵ�. dirname���� ��� tcl������ �޽��� īŻ�α׸� �����Ѵ�.
proc mcExtract {dirname existing} {
	lappend already {}
	
	if {$existing != {}} {
		set catalog [open $existing r]
		fconfigure $catalog -encoding utf-8
		while {![eof $catalog]} {
			set line [gets $catalog]
			if {[lindex $line 0] == {mcset}} {
				set locale [lindex $line 1]
				lappend already [lindex $line 2]
			}
		}
		close $catalog
	} else {
		set existing [file dirname $dirname]/catalog.msg
	}
	set catalog [open $existing a]
	fconfigure $catalog -encoding utf-8
	
	foreach relPath [scan_dir $dirname *.tcl] {
		set srcFile [open $relPath r]
		set srcText [read $srcFile]
		close $srcFile
		
		# �� ���Խ� ����µ� �� �������... �Դٰ� ����������� ���԰��ɼ��� ����.
		# �� ���� ����� ������.
		foreach {whole quote} [regexp -all -inline {\[mc (\{[^\}]*\}|"[^"]*"|[^]]*)} $srcText] {
			set focus [lindex $quote 0]
			if [string equal $focus $quote] {
				set quote \{$quote\}
			}
			if {[lsearch -exact $already $focus] == -1} {
				lappend already $focus
				puts $catalog "mcset $locale {$focus} {$focus}"
			}
		}
	}
	set ::already $already
	close $catalog
}

proc loadcfg {name {default ""}} {
	if [info exists ::config($name)] {
		return $::config($name)
	} {
		return $default
	}
}

proc setcfg {name value} {
	set ::config($name) $value
}

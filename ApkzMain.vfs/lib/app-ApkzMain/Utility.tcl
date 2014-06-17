
oo::class create InterChan {
	constructor {body} {
		oo::objdefine [self] method write {chan data} $body
	}
	method initialize {ch mode} {
		return {initialize finalize watch write}
	}
	method finalize {ch} {
		my destroy
	}
	method watch {ch events} {
		# Must be present but we ignore it because we do not
		# post any events
	}
}

oo::class create CapturingChan {
	variable var
	constructor {varnameOrArgs {body ""}} {
		# Make an alias from the instance variable to the global variable
		if {[llength $varnameOrArgs] == 2} {
			oo::objdefine [self] method write $varnameOrArgs $body
		} {
			my eval [list upvar \#0 $varnameOrArgs var]
		}
	}
	method initialize {handle mode} {
		if {$mode ne "write"} {error "can't handle reading"}
		return {finalize initialize write}
	}
	method finalize {handle} {
		# Do nothing, but mandatory that it exists
	}
	method write {handle bytes} {
		append var $bytes
		# Return the empty string, as we are swallowing the bytes
		return {}
	}
}

#set myBuffer ""
#chan push stdout [CapturingChan new myBuffer]
#chan pop stdout


# kostix's snippet from tcler bin
proc scan_dir {dirname pattern} {
	set out [list]
	foreach d [glob -type d -nocomplain -dir $dirname *] {
		set out [concat $out [scan_dir $d $pattern]]
	}
	concat $out [glob -type f -nocomplain -dir $dirname {*}$pattern]
}

if {$tcl_platform(platform) == {windows}} {
#	-chan 같은 걸 쓸땐 tcl::chan::fifo같은 걸 넣을 수 있다.
#	chan pipe를 그대로 쓰려면 readable에서 실시간으로 처리하도록 해주어야 한다.
	proc bgopen {args} {
#		catch {
#			::twapi::allocate_console
#			set hWnd [::twapi::get_console_window]
#			::twapi::hide_window $hWnd
#		}
		set w(out) $::wrDebug
		set w(err) $::wrError
		set condErr {}

		set cmdline $args
		set opTable {-chan -outchan -errchan -conderror --}
		foreach {opt val} $args {
			if [catch {set opt [::tcl::prefix match $opTable $opt]}] break
			switch $opt {
			-chan { set w(out) $val
					set w(err) $val }
			-outchan { set w(out) $val }
			-errchan { set w(err) $val }
			-conderror { set condErr $val }
			-- {
				set cmdline [lrange $cmdline 1 end]
				break
			}}
			set cmdline [lrange $cmdline 2 end]
		}

		foreach ch {out err} {
#			refchan doesn't have OS handle, so mediate channel required.
			# 이건 ADB에서만 써야 함. 일반화 시키려면 저 encoding과 translation이 심히 걸림.
			if ![string match file* $w($ch)] {
				set dest $w($ch)
				lassign [chan pipe] r($ch) w($ch)
				chan configure $r($ch) -blocking false -buffering line -encoding utf-8
				chan configure $w($ch) -blocking false -buffering line -encoding utf-8
				append flushPhrase "puts -nonewline {$dest} \[read {$r($ch)}\];"
				chan event $r($ch) readable $flushPhrase
			}
		}

		puts $::wrVerbose $cmdline
		set pid [exec -- {*}$cmdline >@ $w(out) 2>@ $w(err) &]
		
		set hProc [twapi::get_process_handle $pid -access generic_all]
		set bgAlive($pid) 0
		twapi::wait_on_handle $hProc -executeonce 1 -async [list set ::bgAlive($pid) 1]\;#
		vwait ::bgAlive($pid)
		set exitcode [twapi::get_process_exit_code $hProc]
		twapi::close_handle $hProc
		if {$::bgAlive($pid) eq {suspend}} {
			error {Canceled by user} {} {CustomError bgopenCancel}
		}
		unset ::bgAlive($pid)
		
		append flushPhrase "chan flush $w(out); chan flush $w(err);"
		eval $flushPhrase
		foreach ch {out err} {
			if [info exists r($ch)] {
				chan configure $w($ch) -blocking true
				chan configure $r($ch) -blocking true
				chan close $w($ch)
				chan close $r($ch)
			}
		}

		if $exitcode$condErr {
			error [mc {Runtime error occured.}] $args [list CustomError bgopenError $exitcode]
		}
		return $exitcode
	}
	
	bind . <Destroy> {+
		foreach pid [array names ::bgAlive] {
			set ::bgAlive($pid) suspend
		}
	}

} else {
	proc bgopen_handler {callback chan} {
		append ::bgData($chan) [set data [read $chan]]
		catch {{*}$callback $data}

		if {[eof $chan]} {
			fconfigure $chan -blocking true
			set returnInfo {}
			set isErr [catch {close $chan} errmsg returnInfo]
			# errorinfo는 errmsg에 스택트레이스가 더 붙은 것이다.
			# 여기선 사전에 담아두기만 하고, bgopen에서 error를 호출한다.
			dict set returnInfo -errormsg $errmsg
			dict set returnInfo -stdout $::bgData($chan)
			unset ::bgData($chan)
			set ::bgAlive($chan) $returnInfo
		}
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
			# errmsg로 지금까지 프로그램이 출력한 데이터(stdout)를 돌려줌.
			error [dict get $ret -stdout] [dict get $ret -errorinfo] [dict get $ret -errorcode]
		}
		return [dict get $ret -stdout]
	}
}

# 파이썬의 range랑 같다. 리눅스의 seq랑 같은지는 모르겠지만.
proc seq args {
	set res {}
	switch [llength $args] {
	1 {
		lassign $args end
		for {set i 0} {$i < $end} {incr i} {lappend res $i}
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

proc rdbleFile {args} {
	foreach file $args {
		if ![file isfile $file]||![file readable $file] {
			return false
		}
	}
	return true
}

proc AdaptPath file {file nativename [file normalize $file]}

package require http
proc httpcopy {url {file ""}} {
	set token [::http::geturl $url -progress httpCopyProgress]

	#전역범위의 '배열'이라서 upvar처리를 해야한다.
	upvar #0 $token state
	if ![info exist state] {error 1}

	# HTTP 리다이렉션 처리.
	# 1. 헤더를 이용한 방법. dict는 대소문자 구분이 힘들어 안 됨.
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

# Not guarantee uniqueness
proc generateID {} {
	return [format {_%08X} [expr {int(rand() * 16 ** 8)}]]
}

proc InputDlg {msg} {
	set focusing {
		raise .pul
		focus .pul.entry
	}

	if [winfo exist .pul] {
		eval $focusing
		return {}
	} {
		toplevel .pul
		wm minsize .pul 300 20
	}
	wm title .pul [mc {Input}]

	set packOption {-side top -fill x -expand true}
	pack [label .pul.label -text $msg -anchor center] {*}$packOption
	pack [ttk::combobox .pul.entry -values [lrange $::hist($msg) 1 end]] {*}$packOption
	.pul.entry insert 0 [lindex $::hist($msg) 0]
	.pul.entry selection range 0 end

	# 까탈스러운 곳. []을 치환해주질 않아 eval로 직접.
	bind .pul.entry <Return> [list eval [info coroutine] {[.pul.entry get]}]
	bind .pul <Escape> {destroy .pul}
	bindtags .pul INPUTDLG
	bind INPUTDLG <Destroy> [list [info coroutine]]
	
	eval $focusing
	set ret [yield]

	if [winfo exist .pul] {
		bind INPUTDLG <Destroy> {}
		destroy .pul
	}
	return $ret
}

proc allwin {{widget .}} {
	set ret [string repeat { } [regexp -all {\.} $widget]]$widget
	foreach child [winfo children $widget] {
		append ret \n[allwin $child]
	}
	return $ret
}

proc modeless_dialog args {
	after 10 {tk::SetFocusGrab .}
	return [tk_dialog {*}$args]
}

proc coproc {name arg body} {
	proc $name $arg [format {
		coroutine "%s[generateID]" apply [list %s]
	} [namespace tail $name] [list $arg $body]]
}

proc procname {} {
	return [lindex [info level -1] 0]
}
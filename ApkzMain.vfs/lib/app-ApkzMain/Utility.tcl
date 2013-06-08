# 유지보수 코드인 mcExtract가 있다.
# 나중에 테스트코드가 추가되면 임시로 여기에 넣어도 될 것 같음.


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
		set isErr [catch {close $chan} errmsg ::bgAlive($chan)]
		# errorinfo는 errmsg에 스택트레이스가 더 붙은 것이다.
		# 여기선 사전에 담아두기만 하고, bgopen에서 error를 호출한다.
		dict set ::bgAlive($chan) -errormsg $errmsg
		dict set ::bgAlive($chan) -stdout $::bgData($chan)
		unset ::bgData($chan)
		set ::bgReturn($chan) 1
	}
}

proc bgopen {callback args} {
	set chan [open "| $args 2>@1" r]
	fconfigure $chan -blocking false
	fileevent $chan readable [list bgopen_handler $callback $chan]
	set ::bgReturn($chan) 0
	vwait ::bgReturn($chan)

	unset ::bgReturn($chan)
	set ret $::bgAlive($chan)
	unset ::bgAlive($chan)
	pval ret
	if {[dict get $ret -code] == 1} {
		# errmsg로 지금까지 프로그램이 출력한 데이터(stdout)를 돌려줌.
		error [dict get $ret -stdout] [dict get $ret -errorinfo] [dict get $ret -errorcode]
	}
	return [dict get $ret -stdout]
}

# 파이썬의 range랑 같다. 리눅스의 seq랑 같은지는 모르겠지만.
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

# 관리코드. dirname하위 모든 tcl파일의 메시지 카탈로그를 생성한다.
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
		
		# 이 정규식 만드는데 좀 어려웠음... 게다가 만들었음에도 결함가능성이 보임.
		# 더 좋은 방법이 없을까.
		foreach {whole quote} [regexp -all -inline {\[mc (\{[^\}]*\}|"[^"]*"|[^]]*)} $srcText] {
			set focus [lindex $quote 0]
			if [string equal $focus $quote] {
				set quote \{$quote\}
			}
			if {[lsearch -exact $already $focus] == -1} {
				lappend already $focus
				puts $catalog "mcset $locale $focus $focus"
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

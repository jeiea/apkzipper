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
	{*}$callback [read $chan]
	if {[eof $chan]} {
		fconfigure $chan -blocking true
		set ::bgAlive($chan) [catch {close $chan} {} erropt]
		if $::bgAlive($chan) {
			{*}$callback "\n[mc ERROR] $::bgAlive($chan): [dict get $erropt -errorinfo]\n"
		}
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
	
	# 2. �ڹٽ�ũ��Ʈ�� �̿��� ��� 
	set data [::http::data $token]
	if [regexp -nocase {<.*script.*>.*location\.href=['"]?([^'"]*)['"]?.*</script>} $data whole redir] {
		puts $redir
		return [httpcopy [string trim $redir] $file]
	}
	if [regexp -nocase {<.*script.*>.*location\.replace(['"]?([^'"]*)['"]?).*</script>} $data whole redir] {
		puts $redir
		return [httpcopy [string trim $redir] $file]
	}
	
	# 3. ��Ÿ�±׸� �̿��� ���
	if [regexp -nocase {<meta\s+http-equiv\s+=.*refresh.*url=['"]?([^'"]*)['"]?>} $data whole redir] {
		return [httpcopy [string trim $redir] $file]
	}
	
	if {$file != ""} {
		set out [open $file wb]
		fconfigure $out -encoding binary -translation binary
		puts -nonewline $out $data
		close $out
		::http::cleanup $token
	} {
		set ret $data
		::http::cleanup $token
		return $ret
	}
}

proc httpCopyProgress {token total current} {
	puts stderr "$current/$total\n"
	flush stderr
}

proc max args {
	if ![llength $args] return
	set ret [lindex $args 0]
	foreach item $args {
		if {$ret < $item} {
			set ret $item
		}
	}
	return $ret
}

proc min args {
	if ![llength $args] return
	set ret [lindex $args 0]
	foreach item $args {
		if {$ret > $item} {
			set ret $item
		}
	}
	return $ret
}


proc InputDlg {msg args} {
	set id [string map {. {}} [expr rand()]]
	global inputvalue$id {}

	toplevel .pul
	wm title .pul [mc {Input}]

	if {$args != {}} {
		set args [list -text $args]
	}
	pack [ttk::label .pul.label -text $msg] -side top
	pack [ttk::entry .pul.entry] -side bottom -fill x
	.pul.entry insert 0 $args
	.pul.entry selection range 0 end
	foreach widget {.pul .pul.label .pul.entry} {
		bind $widget <Escape> {destroy .pul}
	}
	bind .pul.entry <Return> [subst {
		puts \[.pul.entry get\]
		set ::inputvalue$id \[.pul.entry get\]
		destroy .pul
	}]
	raise .pul
	focus .pul.entry

	vwait ::inputvalue$id
	set ret [subst $[subst ::inputvalue$id]]
	unset ::inputvalue$id
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
		foreach {whole quote} [regexp -all -inline {\[mc (\{[^\}]*\}|"[^"]*"|[^] ]*)} $srcText] {
			set focus [lindex $quote 0]
			if [string equal $focus $quote] {
				set quote \{$quote\}
			}
			if {[lsearch -exact $already $focus] == -1} {
				lappend already $focus
				puts $catalog "mcset $locale $quote {}"
			}
		}
	}
	set ::already $already
	close $catalog
}

# 전부 디버그때만 동작해야 할 부분. 릴리즈땐 없애야 한다.
# 함수명 검색 잊지 말자.
console show
mcExtract $::libpath $::libpath/locale/ko.msg

proc pval {args} {
	foreach varname $args {
		upvar $varname value
		puts "$varname: $value"
	}
}

proc adb args {
	WinADB::adb {*}$args
}

proc leavePrefix {cmdstr code result op} {
	set codename [lindex {TCL_OK TCL_ERROR TCL_RETURN TCL_BREAK TCL_CONTINUE} $code]
	puts [format "cmdstr: %s\n%s: %s\n" \
			$cmdstr $codename $result]
}
#trace add execution Session::getRecentSessionNames leavestep leavePrefix

# errorinfo는 번잡하다. 좀 가공해야지. proc 래핑이라 하는건가?
# Tk에서 text위젯에 더블클릭 버그를 일으켰다. 뭐가 문젠 것 같은데.
#rename proc _My_proc
#_My_proc proc {name args body} {
#	_My_proc $name $args [format {set err [catch {%s} ret errinf]
#		if $err {
#			if [dict exist $errinf -errorinfo] {
#				set info [dict get $errinf -errorinfo]
#				if [info exist info] {puts stderr $info}
#				for {set lvl [expr [info level] -1]} {$lvl > 0} {incr lvl -1} {
#					puts stderr " LEVEL $lvl: [info level $lvl]"
#				}
#			}
#		}
#		return $ret} $body]
#}

# 재귀적으로 verbose걸어버리면 편할 텐데. 근데... 무진장 어렵다. 변수값만 확인하는게 ㅡㅡ;;
# trace에 비슷한 게 있음... 잘 알아둬야 하나
proc verbose_eval {script} {
	set cmd ""
	foreach line [split $script \n] {
		if {$line eq ""} {continue}
		append cmd $line\n
		if { [info complete $cmd] } {
			puts -nonewline $cmd
			puts -nonewline [uplevel 1 $cmd]
			set cmd ""
		}
	}
}

# http://wiki.tcl.tk/16183
proc stacktrace {} {
	set stack "Stack trace:\n"
	for {set i 1} {$i < [info level]} {incr i} {
		set lvl [info level -$i]
#		set pname [lindex $lvl 0]
		set pname [uplevel $i "namespace which [list [lindex $lvl 0]]"]
		append stack [string repeat " " $i]$pname
		foreach value [lrange $lvl 1 end] arg [info args $pname] {
			if {$value eq ""} {
				info default $pname $arg value
			}
			append stack " $arg='$value'"
		}
		append stack \n
	}
	return $stack
}


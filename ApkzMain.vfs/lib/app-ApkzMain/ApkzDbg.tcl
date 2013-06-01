# 전부 디버그때만 동작해야 할 부분. 릴리즈땐 없애야 한다.
console show
mcExtract . $::libpath/locale/ko.msg

proc getcapp {} {
	global cApp
	GetNativePathArray $::cAppPaths cApp
}

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

# 재귀적으로 verbose걸어버리면 편할 텐데. 이따가 수정하자
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


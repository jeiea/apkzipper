# ���� ����׶��� �����ؾ� �� �κ�. ����� ���־� �Ѵ�.
console show
mcExtract . $::libpath/locale/ko.msg

proc getcapp {} {
	global cApp
	GetNativePathArray $::cAppPaths cApp
}

# errorinfo�� �����ϴ�. �� �����ؾ���. proc �����̶� �ϴ°ǰ�?
# Tk���� text������ ����Ŭ�� ���׸� �����״�. ���� ���� �� ������.
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

# ��������� verbose�ɾ������ ���� �ٵ�. �̵��� ��������
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


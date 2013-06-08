# ���� ����׶��� �����ؾ� �� �κ�. ����� ���־� �Ѵ�.
console show
mcExtract . $::libpath/locale/ko.msg

proc pval {args} {
	foreach varname $args {
		upvar $varname value
		puts "$varname: $value"
	}
	puts {} 
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

# ��������� verbose�ɾ������ ���� �ٵ�. �ٵ�... ������ ��ƴ�. �������� Ȯ���ϴ°� �Ѥ�;;
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


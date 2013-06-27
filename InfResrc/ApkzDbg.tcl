# ���� ����׶��� �����ؾ� �� �κ�. ����� ���־� �Ѵ�.
# �Լ��� �˻� ���� ����.
console show

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
#trace add execution ListAndConfirmDlg leavestep leavePrefix

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
# trace�� ����� �� ����... �� �˾Ƶ־� �ϳ�
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
		set cmd [uplevel $i "namespace which [list [lindex $lvl 0]]"]
		append stack [string repeat " " $i]$cmd
	
		set realArgs [lrange $lvl 1 end]
		set isCommand [catch {set protoArgs [info args $cmd]}]
		if $isCommand {
			append stack " $realArgs"
			continue
		}
		
		foreach value $realArgs name $protoArgs {
			if {$value eq ""} {
				info default $cmd $name value
			}
			append stack " $name='$value'"
		}
		append stack \n
	}
	return $stack
}

# tooltip�������� �̹� ������ �޽����� �� ������Ű�� ������ ���� �߻�.
# ApkzDbg�� ����� �ڵ��... �⺻ ��Ű���� �ٲٱ� �����ϰ� ���⿡ ���ܸ� �߰���Ű�� ���� ���ڴ�.
proc ::msgcat::mcunknown {locale srcstr args} {
	if [regexp ::tooltip::show [stacktrace]] {return $srcstr}

	foreach candidate [::msgcat::mcpreferences] {
		if [file readable $::libpath/locale/$candidate.msg] {
			set catalog [open $::libpath/locale/$candidate.msg a]
			fconfigure $catalog -encoding utf-8
			puts $catalog "mcset $candidate {$srcstr} {$srcstr}"
			uplevel #0 [list ::msgcat::mcset $candidate $srcstr]
			puts "new message: $srcstr\n at [stacktrace]"
			close $catalog
			break
		}
	}
	
	return [expr {[llength $args] ? [format $srcstr {*}$args] : $srcstr}]
}

# �����ڵ�. mc�� ���� ������� mcunknown���� constant message�� �̸� īŻ�α׿� ��Ͻ�Ų��.
# foreach������ �������� ��Ȳ������ message�� ���� ������ִ� ���� �����ϰ�,
# �Ǽ��� ���߸� ��츦 ����� mcunknown�� ��Ͻ��� �⵵�� �ߴ�.
proc mcExtract {dirname} {
	foreach relPath [scan_dir $dirname *.tcl] {
		set srcFile [open $relPath r]
		set srcText [read $srcFile]
		close $srcFile
		
		# ���Խ����� �ļ��� ���� �� ����. ������ �� �������� ���� dynamic���� �����ϰ�
		# fail���ѵ� ��� ���� ���̴�.
		# {\[(mc (\{[^\}]*\}|"[^"]*"|\s*|[^]]*)*)\]} �̰� �� �� ����
		foreach {whole phrase arg} [regexp -all -inline \
			{\[(mc (\{[^\}]*\}|"[^"]*"|\s*|\w*)*)\]} $srcText] {
				set a [catch [list uplevel #0 $phrase]]
		}
	}
}
mcExtract $::libpath

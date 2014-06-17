# ���� ����׶��� �����ؾ� �� �κ�. ����� ���־� �Ѵ�.
# �Լ��� �˻� ���� ����.
console show

package require tcltest

set testlog [file join $::exeDir Release test.log]
file delete $testlog
::tcltest::configure -testdir [file dirname [file normalize [info script]]]
::tcltest::configure -tmpdir [file normalize [info script]/../../Release/testtemp]
::tcltest::configure -outfile $testlog -errfile $testlog -singleproc 1

proc r {} {::tcltest::runAllTests}

::tcltest::configure -loadfile [tcltest::configure -testdir]/Trial.test

proc d {} {::tcltest::loadTestedCommands}

cd {D:/workspace/Apkz/Release}

# unittest
#after 500 {Config::showDialog}
#coroutine na ListAndConfirmDlg {asdf} {a b c} {1 2 3 4 5 6}

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
	    set isError [catch [list uplevel #0 $phrase]]
	    if {0} { puts "[file tail $relPath]: $phrase" }
	}
    }
}

mcExtract $::libpath

proc file_equal {a b} {
    global aCRC bCRC
    if {![file exists $a] || ![file exists $b]} {
	return 0
    }

    if {[file size $a] != [file size $b]} {
	return 0
    }

    package require tcl::transform::crc32

    set aCheck [tcl::transform::crc32 [open $a] -read-variable aCRC]
    set bCheck [tcl::transform::crc32 [open $b] -read-variable bCRC]
    read $aCheck
    read $bCheck
    close $aCheck
    close $bCheck
    set result [expr {($aCRC eq $bCRC)}]
    unset aCRC
    unset bCRC
    return $result
}
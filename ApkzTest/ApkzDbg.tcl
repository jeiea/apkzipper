# 전부 디버그때만 동작해야 할 부분. 릴리즈땐 없애야 한다.
# 함수명 검색 잊지 말자.
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

# tooltip같은데서 이미 번역된 메시지를 또 번역시키는 뭣같은 일이 발생.
# ApkzDbg는 디버그 코드니... 기본 패키지를 바꾸긴 찝찝하고 여기에 예외를 추가시키는 것이 낫겠다.
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

# 관리코드. mc를 강제 실행시켜 mcunknown에서 constant message를 미리 카탈로그에 등록시킨다.
# foreach문같은 가변적인 상황에서의 message는 직접 등록해주는 것이 안전하고,
# 실수로 빠뜨릴 경우를 대비해 mcunknown을 등록시켜 잡도록 했다.
proc mcExtract {dirname} {
    foreach relPath [scan_dir $dirname *.tcl] {
	set srcFile [open $relPath r]
	set srcText [read $srcFile]
	close $srcFile

	# 정규식으로 파서를 만들 순 없다. 어차피 그 정도까지 가면 dynamic으로 간주하고
	# fail시켜도 상관 없을 것이다.
	# {\[(mc (\{[^\}]*\}|"[^"]*"|\s*|[^]]*)*)\]} 이건 왜 안 되지
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
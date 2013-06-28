namespace eval Session {
	variable cAppPaths {}
	variable currentOp {}
}
oo::class create Session {
	
}
set cAppPaths {}

proc Session::CommandParser line {
	set cmd [string tolower [lindex $line 0]]
	set line [regsub -all {"([^"]*)"} $line {{\1}}]
	
	# HACK: 나중에 VFS처럼 만들어야... 이것도 좋지만 좀 더 깔끔하게
	if {$cmd eq {0}} {
		puts $::wrDebug "adb pull [lrange $line 1 end]"
		WinADB::adb pull {*}[lrange $line 1 end]
		return
	}

	set table {push pull exit shell connect}
	catch {set cmd [::tcl::prefix match $table $cmd]}
	switch $cmd {
		exit {
			destroy .
		}
		shell {
			switch [llength $line] {
				1 {::WinADB::adb_waitfor Shell}
				2 {
					puts $::wrInfo "$ [lrange $line 1 end]"
					::WinADB::adb shell {*}[lrange $line 1 end]
				}
			}
		}
		connect {
			switch [llength $line] {
				1 {coroutine ADBcon[generateID] {::WinADB::ADB connect}}
				2 {coroutine ADBcon[generateID] {::WinADB::ADB connect} [lindex $line 1]}
			}
		}
		push {
			switch [llength $line] {
				1 {coroutine Command[generateID] TraverseCApp {::Export to phone}}
				2 {coroutine Command[generateID] TraverseCApp {::Export to phone} [lindex $line 1]; puts $line}
				3 {coroutine Command[generateID] WinADB::adb push [lindex $line 1] [lindex $line 2]}
			}
		}
		pull {
			switch [llength $line] {
				1 {coroutine Command[generateID] TraverseCApp {::Import from phone}}
				2 {coroutine Command[generateID] TraverseCApp {::Import from phone} [lindex $line 1]}
				3 {coroutine Command[generateID] WinADB::adb pull [lindex $line 1] [lindex $line 2]}
			}
		}
		default {
			if [string is digit $cmd] {
				coroutine Command[generateID] TraverseCApp "::[lindex $::config(btns) [expr $cmd * 3 + 1]]"
			}
		}
	}
}

# 당장은 필요없지만 나중에 임시 세션을 만들 경우를 위해 남겨 둠
proc Session::makeSessionName apps {
	set someFilename [file tail [lindex $apps 0]]
	set num [llength $apps]
	if {$num > 1} {
		return [mc {%1$s and %2$d others} $someFilename [expr $num - 1]]
	}
	return $someFilename
}

proc Session::getRecentSessionNames {} {
	foreach apkList $::hist(recentApk) {
		lappend numBucket([llength $apkList]) $apkList
	}
	foreach idx [array names numBucket] {
		set numBucket($idx) [join $numBucket($idx) { }]
	}

	set ret {}
	foreach namingTarget $::hist(recentApk) {
		set label {}
		foreach apk $namingTarget {
			set idxDuplicate [lsearch -exact -all $numBucket([llength $namingTarget]) $apk]
			if {[llength $idxDuplicate] == 1} {
				set label $apk
				break
			}
		}
		if {$label ne {}} {
			set filename [file tail $label]
			set otherNum [expr [llength $namingTarget] - 1]
			if {$otherNum == 0} {
				lappend ret $filename
			} {
				lappend ret [mc {%1$s and %2$d others} $filename $otherNum]
			}
		} {
			# safecode
			lappend ret {}
		}
	}
	
	return $ret
}

proc Session::filterAndLoad paths {
	set qualified [list]
	set reply $::config(askExtension)

	foreach path $paths {
		if ![file readable $path] {
			puts $::wrError [mc {Access denied: %s} $path]
			continue
		} elseif [file isdirectory $path] {
			lappend paths [glob $path {*.apk *.jar}]
			continue
		} elseif {!(
			[string match -nocase *.apk $path] ||
			[string match -nocase *.jar $path] ) && $reply != 2
		} {
			if {$reply == 3} continue

			set reply [tk_dialog .foo \
				[mc {Extension mismatch}] \
				[mc "Do you want to import this?\n%s" [file nativename $path]] \
				warning 3 [mc Yes] [mc No] [mc {Yes to all}] [mc {No to all}]]

			if {$reply == 3 || $reply == 1} continue
			lappend qualified $path
		} else {
			lappend qualified $path
		}
	}

	set ::cAppPaths $qualified
	if {$qualified ne {}} {
		addHist recentApk $::cAppPaths
	}
	set ::View::cappLabel [makeSessionName $::cAppPaths]
}

plugin {Select app} {args} {
	{Session::Select app} {*}$args
}

proc {Session::Select app} {args} {
	global cAppPaths

	if {$args != {}} {
		set cAppPaths [lindex $args 0]
	} {
		set cAppPaths [dlgSelectAppFiles [mc {You can select multiple files or folders}]]
	}

	set cAppPaths [lsort $cAppPaths]
	filterAndLoad $cAppPaths
	if {$cAppPaths == {}} return
}

plugin {Select app recent} {} {
	destroy .recentPop
	set m [menu .recentPop -tearoff 0]

	foreach label [Session::getRecentSessionNames] apkList $::hist(recentApk) {
		$m add command -label $label \
			-command [namespace code [list {Session::Select app} $apkList]]
	}

	tk_popup .recentPop [winfo pointerx .] [winfo pointery .]
}

#plugin {Import project} {} {
#	set initdir [expr [info exist ::config(lastBrowseDir)] ? $::config(lastBrowseDir) : $::exeDir]
#	set proj [tk_chooseDirectory -initialdir $initdir -mustexist 1 -title [mc {Choose project directory}]]
#}

proc Session::running_other_task? {} {
	variable currentOp

	if {$currentOp != ""} {
		if ![winfo exist .mlsWait] {
			toplevel .mlsWait
			wm title .mlsWait [mc {Please wait}]
			pack [ttk::label .mlsWait.msg -text [mc {Please wait}]\n[mc {Already op exist}]] -expand 1 -fill both
		}
		raise .mlsWait
		after 3000 {destroy .mlsWait}
		return true
	} {
		return false
	}
}

proc Session::TraverseCApp {pluginName args} {
	global cAppPaths
	variable currentOp

	if [running_other_task?] return

	if ![string match "apkPath*" [lindex [info object definition $pluginName business] 0]] {
		$pluginName business {*}$args
		return
	}

	set currentOp $pluginName
	if [info exist cAppPaths] {
		foreach apkPath $cAppPaths {
			try {
				$pluginName business $apkPath {*}$args
			} trap {CustomError} {msg info} {
				puts $::wrError $msg
				puts $::wrVerbose $info
			} on error {msg info} {
				set errorinfo [dict get $info -errorinfo]
				if {[string first charset.MalformedInputException $errorinfo] != -1} {
					puts $::wrWarning [join [list \
						[mc ERROR]:\ [mc {File name malformed.}]\n \
						[mc {Please retry after rename. (e.g. test.apk)}]\n] {}]
				} {
					puts $::wrError "[mc ERROR]: $msg\n"
					puts $::wrVerbose $info\n
				}
			}
		}
	}
	set currentOp {}
}

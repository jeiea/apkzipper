namespace eval Session {
	variable cAppPaths {}
	variable currentOp {}
}

proc Session::CommandParser command {
	set cmd [lindex $command 0]
	# HACK: 나중에 VFS처럼 만들어야... 이것도 좋지만 좀 더 깔끔하게
	if {$cmd == 0} {
		Print "adb [lrange $command 1 end]"
		WinADB::adb pull {*}[lrange $command 1 end]
		return
	}
	if [string is digit $cmd] {
		TraverseCApp "::[lindex $::config(btns) [expr $cmd * 3 + 1]]"
	}
}

proc Session::makeSessionName apps {
	set someFilename [file tail [lindex $apps 0]]
	set num [llength $apps]
	if {$num > 1} {
		return [mc {%1$s and %2$d others} $someFilename [expr $num - 1]]
	}
	return $someFilename
}

proc Session::filterAndLoad paths {
	set qualified [list]
	set reply $::config(askExtension)

	foreach path $paths {
		if ![file readable $path] {
			::View::Print [mc {Access denied: %1$s} $path]\n
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
	set ::View::cappLabel [makeSessionName $::cAppPaths]
}

plugin {Select app} {args} {
	{Session::Select app} {*}$args
}

proc {Session::Select app} {args} {
	global cAppPaths
	# TODO: 역시 이것도 기본 시작 위치 설정. 나중에.
	#if [string equal $default ""] {set initialfile ""} {set initialfile "-initialfile $default"}

	# 귀찮아서 일단 미리 지정해둠.
	if {$args != {}} {
		set cAppPaths [lindex $args 0]
	} {
		set cAppPaths [dlgSelectAppFiles [mc {You can select multiple files or folders}]]
	}

	filterAndLoad $cAppPaths
	if {$cAppPaths == {}} return
	set idx [lsearch [getRecentSessionNames] $::View::cappLabel]
	if {$idx == -1} {
		set ::hist(recentApk) [concat [list $cAppPaths] $::hist(recentApk)]
	} {
		set ::hist(recentApk) [concat [list $cAppPaths] [lreplace $::hist(recentApk) $idx $idx]]
	}
}

proc Session::getRecentSessionNames {} {
	return [lmap apkList $::hist(recentApk) {makeSessionName $apkList}]
}

plugin {Select app recent} {} {
	destroy .recentPop
	set m [menu .recentPop -tearoff 0]
	foreach recentApks $::hist(recentApk) {
		$m add command -label [Session::makeSessionName $recentApks] \
			-command [namespace code "{Session::Select app} [list $recentApks]"]
	}

	tk_popup .recentPop [winfo pointerx .] [winfo pointery .]
}

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

proc Session::TraverseCApp pluginName {
	global cAppPaths
	variable currentOp

	if [running_other_task?] return

	if ![string match "apkPath*" [lindex [info object definition $pluginName business] 0]] {
		$pluginName business
		return
	}

	set currentOp $pluginName
	try {
		if [info exist cAppPaths] {
			foreach apkPath $cAppPaths {
				if [catch [list $pluginName business $apkPath] errmsg errinfo] {
					if {[dict exist $errinfo -errorcode] &&
						[dict get $errinfo -errorcode] == 100} {
						::View::Print "[mc ERROR]: $errmsg\n"
					} {
						if {[string first charset.MalformedInputException $errmsg] != -1} {
							::View::Print "[mc ERROR]: [mc "File name malformed.\nPlease retry after rename. (e.g. test.apk)"]\n"
						} {
							::View::Print "[mc ERROR]: [dict get $errinfo -errorinfo]\n"
						}
					}
				}
			}
		}
	} finally {set currentOp ""}
}

::View::init
namespace eval Session {
	variable cAppPaths {}
	variable currentOp {}
}

proc Session::CommandParser command {
	set cmd [lindex $command 0]
	# HACK: 나중에 VFS처럼 만들어야... 이것도 좋지만 좀 더 깔끔하게
	if {$cmd == 0} {
		Print "adb [lrange $command 1 end]"
		{::ModApk::Adb pull} {*}[lrange $command 1 end]
		return
	}
	if [string is digit $cmd] {
		TraverseCApp "::ModApk::[lindex $::config(btns) [expr $cmd * 3 + 1]]"
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

proc {Session::Select app} {args} {
	variable types
	global cAppPaths
	# TODO: 역시 이것도 기본 시작 위치 설정. 나중에.
	#if [string equal $default ""] {set initialfile ""} {set initialfile "-initialfile $default"}

	# 귀찮아서 일단 미리 지정해둠.
	if {$args != {}} {
		set cAppPaths [lindex $args 0]
	} {
		set cAppPaths [tk_getOpenFile -filetypes "$types" \
			-multiple 1 -initialdir $::hist(lastBrowsePath) \
			-title [mc {You can select multiple files or folders}]]

		# 같은 구문이 나조차 보기 심히 안 좋지만, initialdir이 바뀌는 걸 사용자가
		# 예상하지 못하는 걸 막기 위함
		if {$cAppPaths == {}} return
		set ::hist(lastBrowsePath) [file dirname [lindex $cAppPaths 0]]
	}

	filterAndLoad $cAppPaths
	if {$cAppPaths == {}} return
	if {[lsearch [getRecentSessionNames] $::View::cappLabel] == -1} {
		set ::hist(recentApk) [concat [list $cAppPaths] $::hist(recentApk)]
	}
}

proc getRecentSessionNames {} {
	return [lmap apkList $::hist(recentApk) {makeSessionName $apkList}]
}

proc {Select app recent} {} {
	destroy .recentPop
	set m [menu .recentPop -tearoff 0]
	foreach recentApks $::hist(recentApk) {
		$m add command -label [makeSessionName $recentApks] \
			-command [namespace code "{Select app} [list $recentApks]"]
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

proc Session::TraverseCApp methodName {
	global cAppPaths
	variable currentOp

	if [running_other_task?] return

	if ![string match "apkPath*" [info args $methodName]] {
		$methodName
		return
	}

	set currentOp $methodName
	try {
		if [info exist cAppPaths] {
			foreach apkPath $cAppPaths {
				if [catch {$methodName $apkPath} errmsg errinfo] {
					if {[dict exist $errinfo -errorcode] &&
						[dict get $errinfo -errorcode] == 100} {
						Print "[mc ERROR]: $errmsg\n"
					} {
						if {[string first charset.MalformedInputException $errmsg] != -1} {
							Print "[mc ERROR]: [mc "File name malformed.\nPlease retry after rename. (e.g. test.apk)"]\n"
						} {
							Print "[mc ERROR]: [dict get $errinfo -errorinfo]\n"
						}
					}
				}
			}
		}
	} finally {set currentOp ""}
}

::View::init
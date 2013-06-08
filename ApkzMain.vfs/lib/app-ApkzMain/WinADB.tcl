namespace eval WinADB {
	variable adbErrMap

	array set adbErrMap {
		INSTALL_PARSE_FAILED_INCONSISTENT_CERTIFICATES
		{}
	}
}

proc WinADB::adb args {
	getVFile AdbWinApi.dll
	getVFile AdbWinUsbApi.dll
	set adbout [bgopen ::View::Print [getVFile adb.exe] {*}$args]

	variable adbErrMap
	foreach errmsg [array names adbErrMap] {
		if [regexp -nocase $errmsg $adbout] {
			eval [namespace code $adbErrMap($errmsg)] [lindex $args 1]
		}
	}
	return $adbout
}

proc WinADB::AskForceInstall path {
	set ans [tk_dialog .askUninstall [mc Confirm] \
		{It can occurs when original application already installed.
		Do you uninstall and retry it?} [mc Abort] [mc {Retry with conserving data}] \
		[mc {Retry with removing data}]]

	switch $ans {
		0 { return }
		1 { set $::config(uninstallConserveData) -k }
		2 { set $::config(uninstallConserveData) {} }
	}
	Uninstall $path
}

proc WinADB::adb_waitfor cmd {
	adb version
	set cmdline "cmd /C echo [mc {Waiting for device... Aborting is Ctrl+C}] & "
	append cmdline "[getVFile adb.exe] wait-for-device & "
	append cmdline "[getVFile adb.exe] [string tolower $cmd]"

	::twapi::allocate_console
	::twapi::create_process {} -cmdline $cmdline -title [mc "ADB $cmd"] -detached 0 -inherithandles 1
#	::twapi::set_console_control_handler {
#		tk_messageBox -title asdf
#		return 1
#	}
#	
	#		::twapi::set_standard_handle stdin [set dupin [::twapi::duplicate_handle [::twapi::get_standard_handle stdin]]]
	#		::twapi::set_standard_handle stdout [set dupout [::twapi::duplicate_handle [::twapi::get_standard_handle stdout]]]
	#		::twapi::set_standard_handle stderr [set duperr [::twapi::duplicate_handle [::twapi::get_standard_handle stderr]]]

	#		set a [::twapi::create_console_screen_buffer]
	#		::twapi::set_console_active_screen_buffer $a
	#		::twapi::set_console_screen_buffer_size $hConOut {80 25}

	set hConOut [::twapi::get_console_handle stdout]
	set bufferInfo [::twapi::get_console_screen_buffer_info $hConOut -all]
	set idealSize [dict get $bufferInfo -windowlocation]
	lset idealSize 2 [expr [lindex $idealSize 2] - 2]
	lset idealSize 3 [expr [lindex $idealSize 3] - 2]
	::twapi::set_console_window_location $hConOut $idealSize
	::twapi::free_console
}

plugin {Import from phone} args {
	if {$args != ""} {
		set path $args
	} {
		set path [InputDlg [mc {Type path of android file}]]
		if [string is space $path] return
	}
	addHist [mc {Type path of android file}] $path

	set dstPath [file dirname [lindex $::cAppPaths 0]]
	if [file writable $dstPath] {
		::WinADB::adb pull $path [AdaptPath $dstPath]
	} {
		::WinADB::adb pull $path [AdaptPath $::vfsRoot/..]
	}
}

# TODO: 占쏙옙占쏙옙 占쏙옙占싹곤옙罐占�占쏙옙占쏙옙占쏙옙占쏙옙 占쏙옙占쏙옙占싸뤄옙 占쏙옙占쏙옙底�.? 占쏙옙占쏙옙
# TODO: 占쌕몌옙 占쏙옙占싹듸옙 占쌘듸옙占쏙옙占쏙옙 푸占쏙옙占싹듸옙占쏙옙... 占싱곤옙 占썲래占쌓뤄옙 처占쏙옙占싹몌옙 占쏙옙占쏙옙占쏙옙 占싻ㅿ옙
plugin {Export to phone} {apkPath {dstPath ""}} {
	if {$dstPath == ""} {
		set pushPath [InputDlg [mc {Type android push path}]]
	} {
		set pushPath $dstPath
	}
	set resultPath [getResult $apkPath]
	if [string is space $pushPath] return
	::View::Print "$resultPath $pushPath\n"
	::View::Print [mc Pushing...]
	::View::Print [mc { finished.}]\n
	lappend ::hist([mc {Type android push path}]) $pushPath
}

proc WinADB::isADBState args {
	adb version
	set state [exec [getVFile adb.exe] get-state]
	foreach check $args {
		if {$state == $check} {
			return true
		}
	}
	return false
}

proc {WinADB::ADB logcat} bLogging {
	variable logcatPID

	if $bLogging {
		set logfile [AdaptPath [file normalize $::vfsRoot/../logcat.txt]]
		WinADB::adb version
		set logcatPID [exec [getVFile adb.exe] logcat >& $logfile &]
		::View::Print "[mc {ADB logcat executed}]: $logfile\n"
	} {
		twapi::end_process $logcatPID -force
		::View::Print [mc {ADB logcat terminated}]
	}
}

proc {WinADB::ADB connect} {} {
	set address [InputDlg [mc {Type android net address}]]
	if [string is space $address] return
	::View::Print [mc {ADB connecting...}]\n
	adb connect $address
	addHist [mc {Type android net address}] $address
	#		TODO: 占싱뤄옙占쏙옙占쏙옙占쏙옙 stdin, stderr, stdout占쏙옙 占쏙옙占쏙옙占쌔억옙 占쏙옙 占쏙옙
	#		::twapi::create_process {} -cmdline "cmd /C echo [mc {Connecting...}] & \
	#			[::getVFile adb.exe] connect $address $config(actionAfterConnect)" \
	#			-title [mc "ADB Connect"] -newconsole 1 -inherithandles 1

	eval $::config(actionAfterConnect)
}

proc {WinADB::Uninstall} apkPath {
	regexp -line {package:.*name='([^']*)'} [aapt dump badging $apkPath] {} pkgName
	adb uninstall $::config(uninstallConserveData) $pkgName
}

plugin {Install} apkPath {
	if ![WinADB::isADBState device] {
		::View::Print [mc {Please connect to device first.}]\n
		return
	}

	tk_messageBox -title asdf
	set resultPath [getResult $apkPath]
	if [file exists $resultPath] {
		set adbout [WinADB::adb install -r $resultPath]
		# 占쏙옙占쏙옙처占쏙옙占쏙옙. 占쏙옙占쏙옙처占쏙옙占쏙옙 adb占쏙옙占쏙옙 占싹곤옙占�占쏙옙占쏙옙.
	}
}
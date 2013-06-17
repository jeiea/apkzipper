namespace eval WinADB {
	variable adbErrMap

	array set adbErrMap [list \
		{Failure \[INSTALL_PARSE_FAILED_INCONSISTENT_CERTIFICATES\]} \
		"[mc ERROR]: [mc {The certificate doesn't match the device's.}]" \
	]
}

proc WinADB::adb args {
	getVFile AdbWinApi.dll
	getVFile AdbWinUsbApi.dll
	set adbout [bgopen [list puts $::wrDebug] [getVFile adb.exe] {*}$args]

	# 여기서 모든 에러를 총괄한다는 걸로. Install에러 Uninstall에러 각각 넣으면 귀찮으니까.
	# 저 adbErrMap을 쓰면 될 듯
	variable adbErrMap
	foreach errmsg [array names adbErrMap] {
		if [regexp -nocase $errmsg $adbout] {
			puts $::wrError $adbErrMap($errmsg)
		}
	}
	return $adbout
}

proc WinADB::askForceInstall path {
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
#		return 1
#	}
#	
	#		::twapi::set_standard_handle stdin [set dupin [::twapi::duplicate_handle [::twapi::get_standard_handle stdin]]]
	#		::twapi::set_standard_handle stdout [set dupout [::twapi::duplicate_handle [::twapi::get_standard_handle stdout]]]
	#		::twapi::set_standard_handle stderr [set duperr [::twapi::duplicate_handle [::twapi::get_standard_handle stderr]]]

	#		set a [::twapi::create_console_screen_buffer]
	#		::twapi::set_console_active_screen_buffer $a
	#		::twapi::set_console_screen_buffer_size $hConOut {80 25}

	global hConOut
	set hConOut [::twapi::get_console_handle stdout]
	set idealSize [::twapi::get_console_window_maxsize]
	set width [expr [lindex $idealSize 0] - 3]
	set height [expr [lindex $idealSize 1] + 3000]
	::twapi::set_console_screen_buffer_size $hConOut [list $width $height]
	set hWnd [::twapi::get_console_window]
	::twapi::maximize_window $hWnd
#	get_window_coordinates HWIN
	::twapi::free_console
}

plugin {Import from phone} args {
	if {$args != ""} {
		set remote $args
	} {
		set remote [InputDlg [mc {Type remote path to pull}]]
		if [string is space $remote] return
	}
	addHist [mc {Type remote path to pull}] $remote

	set primaryApp [lindex $::cAppPaths 0]
	if {$primaryApp ne {}} {
		set local [file dirname $primaryApp]
	} {
		set local $::exeDir
	}
	set local [AdaptPath $local/[file tail $remote]]
	puts $::wrInfo [mc {Pulling... %s --> %s} $remote $local]
	::WinADB::adb pull $remote $local
	{::Select app} business [list $local]
}

# TODO: 넣을 파일경로를 윈도우즈 가상경로로 만들어서..? ㅋㅋ
# TODO: 다른 파일도 자동으로 푸시하도록... 이건 드래그로 처리하면 좋은데 ㅠㅠ
plugin {Export to phone} {apkPath {dstPath ""}} {
	set local [getResultApk $apkPath]
	if [string is space $local] return
	if {$dstPath == ""} {
		set remote [InputDlg [mc {Type remote path to push}]]
	} {
		set remote $dstPath
	}
	if [string is space $remote] return
	puts $::wrInfo [mc {Pushing... %s --> %s} $local $remote]]
	WinADB::adb push $local $remote
	puts $::wrInfo [mc { finished.}]
	addHist [mc {Type remote path to push}] $remote
}

proc WinADB::isADBState args {
	regexp -line {^(unknown|offline|bootloader|device)$} [WinADB::adb get-state] state
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
		set logfile [AdaptPath [file normalize $::exeDir/logcat.txt]]
		WinADB::adb version
		set logcatPID [exec [getVFile adb.exe] logcat >& $logfile &]
		puts $::wrInfo [mc {ADB logcat executed: %s} $logfile]
	} {
		twapi::end_process $logcatPID -force
		puts $::wrInfo [mc {ADB logcat terminated}]
	}
}

proc {WinADB::ADB connect} {} {
	set address [InputDlg [mc {Type android net address}]]
	if [string is space $address] return
	addHist [mc {Type android net address}] $address
	puts $::wrInfo [mc {ADB connecting...}]
	adb connect $address
	#		TODO: 이런식으로 stdin, stderr, stdout을 지정해야 할 듯
	#		::twapi::create_process {} -cmdline "cmd /C echo [mc {Connecting...}] & \
	#			[::getVFile adb.exe] connect $address $config(actionAfterConnect)" \
	#			-title [mc "ADB Connect"] -newconsole 1 -inherithandles 1

#	eval $::config(actionAfterConnect)
}

proc {WinADB::Uninstall} apkPath {
	regexp -line {package:.*name='([^']*)'} [aapt dump badging $apkPath] {} pkgName
	adb uninstall $::config(uninstallConserveData) $pkgName
}

plugin {Install} apkPath {
	if ![WinADB::isADBState device] {
		puts $::wrWarning [mc {Please connect to device first.}]
		return
	}

	set resultPath [getResultApk $apkPath]
	if [file exists $resultPath] {
		puts $::wrInfo [mc {Installing: %s} $resultPath]
		set adbout [WinADB::adb install -r $resultPath]
		# 성공처리만. 에러처리는 adb에서 일괄로 하자.
	}
}
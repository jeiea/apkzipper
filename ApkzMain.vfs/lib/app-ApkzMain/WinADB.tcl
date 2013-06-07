namespace eval WinADB {
	variable adbErrMap

	array set adbErrMap {
		INSTALL_PARSE_FAILED_INCONSISTENT_CERTIFICATES
		{}
	}
}

# HACK: �ӽ������� �̸��� ��ΰ� ����Ǹ� ���ڴµ�... ����� ����� ����?
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
	set cmdline "cmd /C echo [mc {Waiting for device... Aborting is Ctrl+C}] & "
	append cmdline "[::ModApk::getVFile adb.exe] wait-for-device & "
	append cmdline "[::ModApk::getVFile adb.exe] [string tolower $cmd]"

	::twapi::allocate_console
	::twapi::create_process {} -cmdline $cmdline -title [mc "ADB $cmd"] -detached 0 -inherithandles 1
	#	::twapi::set_console_control_handler {
	#		::twapi::free_console
	#		return 1
	#	}
	#		::twapi::set_standard_handle stdin [set dupin [::twapi::duplicate_handle [::twapi::get_standard_handle stdin]]]
	#		::twapi::set_standard_handle stdout [set dupout [::twapi::duplicate_handle [::twapi::get_standard_handle stdout]]]
	#		::twapi::set_standard_handle stderr [set duperr [::twapi::duplicate_handle [::twapi::get_standard_handle stderr]]]

	#		set a [::twapi::create_console_screen_buffer]
	#		::twapi::set_console_active_screen_buffer $a
	#		set hConOut [::twapi::get_console_handle stdout]
	#		::twapi::set_console_screen_buffer_size $hConOut {80 25}

	set bufferInfo [::twapi::get_console_screen_buffer_info $hConOut -all]
	set idealSize [dict get $bufferInfo -windowlocation]
	lset idealSize 2 [expr [lindex $idealSize 2] - 2]
	lset idealSize 3 [expr [lindex $idealSize 3] - 2]
	::twapi::set_console_window_location $hConOut $idealSize
	::twapi::free_console
}

proc {WinADB::Import from phone} args {
	if {$args != ""} {
		set path $args
	} {
		set path [InputDlg [mc {Type path of android file}]]
		if [string is space $path] return
	}

	if [file isdirectory $::vfsdir/../modding] {
		Adb pull $path [AdaptPath $::vfsdir/../modding]
	} {
		Adb pull $path [AdaptPath $::vfsdir/../..]
	}
}

# TODO: ���� ���ϰ�θ� �������� �����η� ����..? ����
# TODO: �ٸ� ���ϵ� �ڵ����� Ǫ���ϵ���... �̰� �巡�׷� ó���ϸ� ������ �Ф�
proc {WinADB::Export to phone} {apkPath {dstPath ""}} {
	if {$dstPath == ""} {
		set ::pushPath [InputDlg [mc {Type android push path}]]
	} {
		set ::pushPath $dstPath
	}
	set resultPath [getResult $apkPath]
	if [string is space $::pushPath] return
	::View::Print "$resultPath $::pushPath\n"
	::View::Print [mc Pushing...]
	Adb push $resultPath $::pushPath
	::View::Print [mc { finished.}]\n
}

proc WinADB::isADBState args {
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
		set logfile [AdaptPath [file normalize $::vfsdir/../logcat.txt]]
		set logcatPID [exec [getVFile adb.exe] logcat >& $logfile &]
		::View::Print "[mc {ADB logcat executed}]: $logfile\n"
	} {
		twapi::end_process $logcatPID -force
		::View::Print [mc {ADB logcat terminated}]
	}
}

proc {WinADB::ADB connect} {} {
	set address [InputDlg [mc {Type android net address}] $::hist(ip)]
	if [string is space $address] return
	set ::hist(ip) $address
	::View::Print [mc {ADB connecting...}]\n

	#		TODO: �̷������� stdin, stderr, stdout�� �����ؾ� �� ��
	#		Adb version�� �ִ� ������ Adb�Լ��� Adb���� ������ �ʿ��� ���ϵ��� �������ֱ� ����. �̰� ADB shell��ɿ��� ����.
	#		ADB version
	#		::twapi::create_process {} -cmdline "cmd /C echo [mc {Connecting...}] & \
	#			[::ModApk::getVFile adb.exe] connect $address $config(actionAfterConnect)" \
	#			-title [mc "ADB Connect"] -newconsole 1 -inherithandles 1

	Adb connect $address
	eval $::config(actionAfterConnect)
}

proc {WinADB::Uninstall} apkPath {
	regexp -line {package:.*name='([^']*)'} [aapt dump badging $apkPath] {} pkgName
	Adb uninstall $::config(uninstallConserveData) $pkgName
}

proc {WinADB::Install} apkPath {
	if ![isADBState device] {
		::View::Print [mc {Please connect to device first.}]\n
		return
	}

	set resultPath [getResult $apkPath]
	if [file exists $resultPath] {
		set adbout [Adb install -r $resultPath]
		# ����ó����. ����ó���� Adb���� �ϰ��� ����.
	}
}